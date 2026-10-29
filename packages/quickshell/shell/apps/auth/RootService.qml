pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Root actions of the shell, one at a time: a part of the shell asks with a
// title, its steps in words and the script; the auth panel (AuthPrompt) shows
// them for a confirmation, and Run starts `pkexec bash -c <script>` from the
// shell itself — polkit then asks the password the first time and, with the
// keep rule (system/etc/polkit-1/rules.d/50-pkexec-keep.rules), not again for
// five minutes; the panel is still shown every time. `finished(tag, ok,
// error)` tells the caller how it went.
Singleton {
  id: root

  // ---- the request ----
  property bool pending: false              // shown, waiting for Run / Cancel
  property bool running: false              // pkexec is on
  property string source: ""                // who asks: "Cleaner"
  property string title: ""                 // "Clean the system"
  property var steps: []                    // [{label, what, command}]
  property string script: ""
  property string tag: ""
  property var flow: null                   // polkit asks our action for the password (set by AuthPrompt)
  readonly property bool asking: flow !== null
  property bool auto: false                 // runs at once, no confirmation (the caller was told to)
  property bool stopped: false              // stop() was asked for the running one
  readonly property string pidFile: "/run/vdx-root.pid"

  signal finished(string tag, bool ok, string error)

  // false when another request is still open
  function request(source, title, steps, script, tag, immediate) {
    if (pending || running) return false;
    root.source = source;
    root.title = title;
    root.steps = steps;
    root.script = script;
    root.tag = tag ?? "";
    auto = immediate === true;
    pending = true;
    if (auto) run();
    return true;
  }

  function run() {
    if (!pending || running) return;
    running = true;
    stopped = false;
    // the root shell writes its pid first: stop() finds it by that
    proc.command = ["pkexec", "/bin/bash", "-c", "echo $$ > " + pidFile + "\n" + script];
    proc.running = true;
  }

  // Cancels a running action: the root shell is held, its children get TERM
  // (pacman stops cleanly), then it goes. A second pkexec, so with the keep
  // rule no password; `finished` then says "cancelled".
  function stop() {
    if (asking) { flow.cancelAuthenticationRequest(); return; }
    if (!running || stopped) return;
    stopped = true;
    stopProc.command = ["pkexec", "/bin/bash", "-c",
      "p=$(cat " + pidFile + ") || exit 1; kill -STOP $p; pkill -TERM -P $p; kill -KILL $p"];
    stopProc.running = true;
  }

  function cancel() {
    if (!pending || running) return;
    const completedTag = tag;
    pending = false;
    finished(completedTag, false, "cancelled");
  }

  Process {
    id: proc
    stderr: StdioCollector { id: err }
    onExited: code => {
      const completedTag = root.tag;
      const cancelled = root.stopped;
      const msg = cancelled ? "cancelled"
                : code === 126 || code === 127 ? "not authorized — cancelled or a wrong password"
                : code === 0 ? "" : (err.text.trim().split("\n").pop() || "failed").slice(0, 160);
      // Publish idle only after the old result is captured. A listener may
      // submit and even stop the next request synchronously from finished().
      root.stopped = false;
      root.pending = false;
      root.running = false;
      root.finished(completedTag, code === 0 && !cancelled, msg);
    }
  }

  Process { id: stopProc }
}
