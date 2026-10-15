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

  signal finished(string tag, bool ok, string error)

  // false when another request is still open
  function request(source, title, steps, script, tag) {
    if (pending || running) return false;
    root.source = source;
    root.title = title;
    root.steps = steps;
    root.script = script;
    root.tag = tag ?? "";
    pending = true;
    return true;
  }

  function run() {
    if (!pending || running) return;
    running = true;
    proc.command = ["pkexec", "/bin/bash", "-c", script];
    proc.running = true;
  }

  function cancel() {
    if (!pending || running) return;
    pending = false;
    finished(tag, false, "cancelled");
  }

  Process {
    id: proc
    stderr: StdioCollector { id: err }
    onExited: code => {
      root.running = false;
      root.pending = false;
      const msg = code === 126 || code === 127 ? "not authorized — cancelled or a wrong password"
                : code === 0 ? "" : (err.text.trim().split("\n").pop() || "failed").slice(0, 160);
      root.finished(root.tag, code === 0, msg);
    }
  }
}
