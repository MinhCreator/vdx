pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../../kit/reply.js" as Reply

// The display settings (scripts/display.py): each monitor's scale, applied at
// once in Hyprland and kept for the next start; the text size for GTK apps.
Singleton {
  id: root

  readonly property string script: Theme.scriptsDir + "/display.py"

  // ---- state ----
  property var monitors: []                 // [{name, model, width, height, refresh, x, y, scale, scales}]
  property real textFactor: 1.0
  property var textScales: []
  property bool busy: false
  property string working: ""               // "scale:<output>", "pos:<output>" or "text", while applied
  property var pending: null                // the value being applied
  property string error: ""

  function refresh() { if (!listProc.running) listProc.running = true; }

  function setScale(name, scale) {
    run(["scale", name, String(scale)], "scale:" + name, scale);
  }

  // x, y in logical pixels; the layout shows the new place while it applies
  function setPosition(name, x, y) {
    run(["position", name, String(x), String(y)], "pos:" + name, [x, y]);
  }

  function setText(factor) {
    run(["text", String(factor)], "text", factor);
  }

  function run(args, key, value) {
    if (busy) return;
    busy = true;
    working = key;
    pending = value;
    error = "";
    actProc.command = ["python3", script].concat(args);
    actProc.running = true;
  }

  function parse(raw) {
    return Reply.parse(raw, "display.py");
  }

  Component.onCompleted: refresh()

  Process {
    id: listProc
    command: ["python3", root.script, "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (!r.ok) { root.error = r.error; return; }
        root.error = "";              // a good list clears the error of an earlier action
        root.monitors = r.monitors;
        root.textFactor = r.text;
        root.textScales = r.textScales;
      }
    }
  }

  Process {
    id: actProc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        root.busy = false;
        root.working = "";
        root.pending = null;
        if (!r.ok) { root.error = r.error; root.refresh(); return; }
        root.refresh();
      }
    }
  }
}
