pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Window mode and snapping (hypr/components/windowmode.lua does the work):
// tiling, floating (like Windows) or scrolling (like Niri), kept in
// ~/.local/state/dotfiles/window-mode for every Hyprland start; and putting
// the active window on a part of the screen. The options (gaps, master,
// column width, floating arrangement) are kept in windows.json and written
// as windows.lua for Hyprland, which reloads.
Singleton {
  id: root

  readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/dotfiles/"
  readonly property string stateFile: stateDir + "window-mode"

  // ---- state ----
  property string mode: "tiling"            // tiling | floating | scrolling
  readonly property var active: Hyprland.activeToplevel

  readonly property var modes: [
    { value: "tiling", label: "Tiling", icon: "layout", about: "Windows share the screen side by side" },
    { value: "floating", label: "Floating", icon: "app-window", about: "Like Windows: drag and resize freely" },
    { value: "scrolling", label: "Scrolling", icon: "columns", about: "Like Niri: a row of columns you scroll" }
  ]

  function setMode(value) {
    if (value === mode) return;
    mode = value;
    // the config reloads: the mode's windows, binds and gestures set from scratch
    run(["bash", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1" && hyprctl reload',
         "_", stateFile, value]);
  }

  // ---- options ----
  readonly property alias opts: opts

  function setOption(key, value) {
    if (opts[key] === value) return;
    opts[key] = value;
    const lua = "-- written by the Shell Manager › Windows (WindowsService.qml)\nreturn {\n"
      + ["gapsIn", "gapsOut", "mfact", "columnWidth"].map(k => "\t" + k + " = " + opts[k] + ",\n").join("")
      + ["newStatus", "arrange"].map(k => "\t" + k + " = \"" + opts[k] + "\",\n").join("") + "}\n";
    run(["bash", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1" && hyprctl reload',
         "_", stateDir + "windows.lua", lua]);
  }

  // spot: left | right | top | bottom | top-left … | left-third … | center | maximize
  function snap(spot) { run(["hyprctl", "eval", "SnapWindow(\"" + spot + "\")"]); }

  function run(command) { Quickshell.execDetached(command); }

  FileView {
    path: root.stateDir + "windows.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
      id: opts
      property int gapsIn: 10
      property int gapsOut: 20
      property real mfact: 0.5
      property string newStatus: "slave"      // master | slave: where a new window goes
      property real columnWidth: 0.5          // scrolling: a new column's share
      property string arrange: "cascade"      // floating: cascade | grid | center
      property bool dock: true                // the bottom dock with minimized windows
    }
  }

  // minimized windows wait on special:minimized (windowmode.lua)
  function minimize(address) { run(["hyprctl", "eval", "MinimizeWindow(" + (address ? "\"" + address + "\"" : "") + ")"]); }
  function restore(address) { run(["hyprctl", "eval", "RestoreWindow(\"" + address + "\")"]); }
  function maximize() { run(["hyprctl", "eval", "MaximizeWindow()"]); }
  function close(address) { run(["hyprctl", "eval", "hl.dispatch(hl.dsp.window.close({ window = \"address:" + address + "\" }))"]); }

  FileView {
    path: root.stateFile
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      const v = text().trim();
      if (v === "tiling" || v === "floating" || v === "scrolling") root.mode = v;
    }
  }
}
