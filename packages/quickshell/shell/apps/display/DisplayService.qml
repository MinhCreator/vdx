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

  readonly property string script: Paths.scriptsDir + "/display.py"

  // ---- state ----
  property var monitors: []                 // [{name, model, width, height, refresh, refreshes, x, y, scale, scales}]
  property real textFactor: 1.0
  property var textScales: []
  property bool busy: false
  property string working: ""               // "scale:<output>", "rate:<output>", "pos:<output>" or "text", while applied
  property var pending: null                // the value being applied
  property string error: ""

  function refresh() { if (!listProc.running) listProc.running = true; }

  function setScale(name, scale) {
    run(["scale", name, String(scale)], "scale:" + name, scale);
  }

  function setRate(name, hz) {
    run(["rate", name, String(hz)], "rate:" + name, hz);
  }

  // ---- scale slider (the bar popup and the window) ----
  // The stops are the scales a monitor offers, evenly spaced along the slider (0..1).
  function stops(m) { return m.scales.map((s, i) => i / Math.max(1, m.scales.length - 1)); }

  // the scale at a slider position
  function stopAt(m, p) { return m.scales[Math.round(p * (m.scales.length - 1))]; }

  // the position of the monitor's scale, or of the one being applied
  function scalePos(m) {
    const v = working === "scale:" + m.name ? pending : m.scale;
    let best = 0;
    m.scales.forEach((s, i) => { if (Math.abs(s - v) < Math.abs(m.scales[best] - v)) best = i; });
    return best / Math.max(1, m.scales.length - 1);
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
