pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// How the shell's own windows open (scripts/shellapps.py): floating or tiled;
// floating at the app's size, a preset share of the monitor or a custom one;
// centred, at the cursor or at a custom spot. A change rewrites the Hyprland
// rules and reloads — it shows the next time the window opens.
Singleton {
  id: root

  readonly property string script: Theme.scriptsDir + "/shellapps.py"

  // ---- the shell's apps (Shell Manager › Shell apps) ----
  // id; label; icon; bind — the name of the Hyprland bind that opens it;
  // window — its id in shellapps.py when it is a window of its own (how it
  // opens is set); settings — its own options page (values in ModuleSettings
  // under `id`, a path from the config root); module — its bar module
  // (BarLayout id), barSettings — that module's own options
  readonly property var entries: [
    { id: "shell-manager", label: "Shell Manager", icon: "settings", bind: "Shell Manager", window: "shell-manager",
      about: "The shell's settings: this window" },
    { id: "taskmanager", label: "Task manager", icon: "activity", bind: "Task manager", window: "task-manager",
      settings: "apps/taskmanager/TaskManagerSettings.qml", module: "taskmanager",
      barSettings: "apps/taskmanager/TaskManagerBarSettings.qml", about: "Processes, CPU and memory, End / Kill" },
    { id: "cleaner", label: "Cleaner", icon: "brush", bind: "Cleaner", window: "cleaner",
      settings: "apps/cleaner/CleanerSettings.qml", module: "cleaner", about: "Caches, the trash, the system; an AI mode" },
    { id: "capture", label: "Capture", icon: "camera", bind: "Capture tool",
      settings: "modules/capture/CaptureSettings.qml", module: "capture", about: "A region, a window or the screen: a shot or a recording" },
    { id: "launcher", label: "System menu", icon: "grid", bind: "System menu", about: "Apps, files, the shell's actions, power" },
    { id: "overview", label: "Overview", icon: "columns", bind: "Overview", about: "Every workspace at once, windows dragged between them" },
    { id: "lock", label: "Lock screen", icon: "lock", bind: "Lock the screen", about: "A session lock with a PAM password" }
  ]

  // ---- state ----
  property var apps: []                     // [{id, title, icon, width, height, settings}]
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
    try { return JSON.parse(text); } catch (e) { return { ok: false, error: "bad reply from shellapps.py" }; }
  }

  Component.onCompleted: refresh()

  Process {
    id: listProc
    command: ["python3", root.script, "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (!r.ok) { root.error = r.error; return; }
        root.apps = r.apps;
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
