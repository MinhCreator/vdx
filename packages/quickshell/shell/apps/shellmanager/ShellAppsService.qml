pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../../kit/reply.js" as Reply

// How the shell's own windows open (scripts/shellapps.py): floating or tiled;
// floating at the app's size, a preset share of the monitor or a custom one;
// centred, at the cursor or at a custom spot. A change rewrites the Hyprland
// rules and reloads — it shows the next time the window opens.
Singleton {
  id: root

  readonly property string script: Paths.scriptsDir + "/shellapps.py"

  // ---- the shell's apps: apps/apps.json, the one registry (the Shell ----
  // Manager, the launcher, scripts/shellapps.py) ----
  // id, label, icon, about; bind — the Hyprland bind that opens it; ipc +
  // open — `qs ipc call <ipc> <open>`; window — {id, title, width, height}
  // when it is a window of its own; settings — its options page (values in
  // ModuleSettings under `id`); module — its bar module (BarLayout id),
  // moduleSettings — that module's options page; desktop — the id of its
  // .desktop file when one is installed (the launcher then lists it once)
  readonly property var entries: {
    try { return JSON.parse(registry.text()); } catch (e) { return []; }
  }

  function run(entry) { Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", entry.ipc, entry.open]); }

  FileView {
    id: registry
    path: Quickshell.shellPath("apps/apps.json")
    blockLoading: true
  }

  // ---- state ----
  property var windows: []                  // [{id, title, icon, ipc, width, height, settings}]
  property var presets: ({})                // name -> [share of width, of height]
  property int minWidth: 480
  property int minHeight: 360
  property var spots: ({})                  // spot -> [x, y] as 0 / 0.5 / 1
  property int gap: 12                      // a spot's distance from the edges
  property int top: 46                      // … and from the top, under the bar
  property bool busy: false
  property string busyApp: ""
  property string error: ""
  property string errorApp: ""

  // ---- the monitor the preview draws (the first one) ----
  readonly property real screenW: Quickshell.screens.length > 0 ? Quickshell.screens[0].width : 1920
  readonly property real screenH: Quickshell.screens.length > 0 ? Quickshell.screens[0].height : 1080

  // the window's size in pixels for some settings
  function sizeOf(app, s) {
    if (s.size === "preset") {
      const p = presets[s.preset] ?? [0.65, 0.7];
      return [Math.round(screenW * p[0]), Math.round(screenH * p[1])];
    }
    return s.size === "custom" ? [s.width, s.height] : [app.width, app.height];
  }

  // a position in words
  function placeName(s) {
    if (s.position === "cursor") return "at the cursor";
    if (s.position === "custom") return "at " + s.x + ", " + s.y;
    return s.position === "center" ? "centred" : s.position.replace("-", " ");
  }

  function refresh() { if (!listProc.running) listProc.running = true; }

  function set(app, change) {
    if (busy) return;
    busy = true;
    busyApp = app.id;
    error = "";
    setProc.command = ["python3", script, "set", app.id, JSON.stringify(change)];
    setProc.running = true;
  }

  function parse(text) {
    return Reply.parse(text, "shellapps.py");
  }

  Component.onCompleted: refresh()

  Process {
    id: listProc
    command: ["python3", root.script, "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (!r.ok) { root.error = r.error; return; }
        root.windows = r.apps;
        root.presets = r.presets;
        root.minWidth = r.minWidth;
        root.minHeight = r.minHeight;
        root.spots = r.spots;
        root.gap = r.gap;
        root.top = r.top;
      }
    }
  }

  Process {
    id: setProc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        root.busy = false;
        if (!r.ok) { root.error = r.error; root.errorApp = root.busyApp; }
        root.busyApp = "";
        root.refresh();
      }
    }
  }
}
