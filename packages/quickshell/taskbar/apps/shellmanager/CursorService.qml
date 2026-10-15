pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The cursor theme for the Shell Manager (scripts/cursors.py): the list
// (curated themes and whatever is installed), installing one into
// ~/.local/share/icons and applying it with a size — at once in Hyprland and
// GTK, and again at every Hyprland start (`cursors.py restore`).
Singleton {
  id: root

  readonly property string script: Theme.scriptsDir + "/cursors.py"

  // ---- state ----
  property var cursors: []                  // [{id, name, installed}]
  property string current: ""
  property int size: 24
  property bool busy: false
  property string working: ""               // the theme being installed / applied
  property string error: ""
  property int pendingSize: 24              // the size to set once an install is done

  function refresh() { if (!listProc.running) listProc.running = true; }

  function apply(cursor, size) {
    if (busy) return;
    busy = true;
    working = cursor.name;
    error = "";
    pendingSize = size;
    run(cursor.installed ? ["set", cursor.name, String(size)] : ["install", cursor.name]);
  }

  function setSize(size) {
    const c = cursors.find(c => c.name === current);
    if (c && size !== root.size) apply(c, size);
  }

  function run(args) {
    actProc.command = ["python3", script].concat(args);
    actProc.running = true;
  }

  function parse(text) {
    try { return JSON.parse(text); } catch (e) { return { ok: false, error: "bad reply from cursors.py" }; }
  }

  Component.onCompleted: refresh()

  Process {
    id: listProc
    command: ["python3", root.script, "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (!r.ok) { root.error = r.error; return; }
        root.cursors = r.cursors;
        root.current = r.current;
        root.size = r.size;
      }
    }
  }

  Process {
    id: actProc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (r.ok && actProc.command[2] === "install") {
          root.run(["set", r.name, String(root.pendingSize)]);
          return;
        }
        root.busy = false;
        root.working = "";
        if (!r.ok) root.error = r.error;
        root.refresh();
      }
    }
  }
}
