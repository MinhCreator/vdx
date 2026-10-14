pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Clipboard history (scripts/clipboard.sh): a `wl-paste --watch` runs for the
// whole session and stores every new selection; the popup reads the list and
// calls copy / delete / clear / limit.
Singleton {
  id: root

  // ---- history -----------------------------------------------------------------
  property var entries: []          // newest first: [{id, kind, preview, path, time}]
  property int limit: 100
  readonly property var limits: [25, 50, 100, 250, 500]
  property string error: ""

  function popupShown() { refresh(); }

  function refresh() { run(listProc, ["list"]); }

  function copy(id) { run(actionProc, ["copy", id]); }
  function remove(id) { run(actionProc, ["delete", id]); }
  function clear() { run(actionProc, ["clear"]); }
  function setLimit(n) { limit = n; run(actionProc, ["limit", String(n)]); }

  function run(proc, args) {
    if (proc.running) return;
    proc.command = ["bash", Theme.scriptsDir + "/clipboard.sh"].concat(args);
    proc.running = true;
  }

  function parse(text, fallback) {
    try { return JSON.parse(text); } catch (e) { return fallback; }
  }

  // every new selection lands in the history; a line after each store
  // refreshes the list. The watcher dies with the shell (pdeathsig), so a
  // restart never leaves an old one storing everything twice.
  Process {
    id: watcher
    command: ["setpriv", "--pdeathsig", "TERM", "bash", Theme.scriptsDir + "/clipboard.sh", "watch"]
    running: true
    stdout: SplitParser { onRead: root.refresh() }
    onExited: restartTimer.start()
  }

  // the watcher must not stay down
  Timer {
    id: restartTimer
    interval: 2000
    onTriggered: watcher.running = true
  }

  // the saved limit
  FileView {
    path: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/clipboard/limit"
    printErrors: false
    onLoaded: { const n = parseInt(text()); if (n > 0) root.limit = n; }
  }

  Process {
    id: listProc
    stdout: StdioCollector {
      onStreamFinished: {
        const list = root.parse(text, null);
        if (Array.isArray(list)) { root.entries = list; root.error = ""; }
        else root.error = "could not read the history";
      }
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text, { ok: false, error: "no answer" });
        root.error = o.ok ? "" : o.error;
        root.refresh();
      }
    }
  }
}
