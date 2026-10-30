pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.components

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
    { value: "tiling", label: "Tiling", icon: "tiling", about: "Windows share the screen side by side" },
    { value: "floating", label: "Floating", icon: "app-window", about: "Like Windows: drag and resize freely" },
    { value: "scrolling", label: "Scrolling", icon: "columns", about: "Like Niri: a row of columns you scroll" }
  ]

  // the current mode's entry, and the modes as plain choices (no icons: three
  // with icons don't fit a popup or a settings row)
  readonly property var current: modes.find(m => m.value === mode) ?? modes[0]
  readonly property var choices: modes.map(m => ({ label: m.label, value: m.value }))

  function setMode(value) {
    if (value === mode) return;
    mode = value;
    // the config reloads: the mode's windows, binds and gestures set from scratch
    Hypr.writeState(stateFile, value + "\n", "hyprctl reload");
  }

  // ---- options ----
  readonly property alias opts: opts

  function setOption(key, value) {
    if (opts[key] === value) return;
    opts[key] = value;
    Hypr.writeState(stateDir + "windows.lua", luaText(), "hyprctl reload");
  }

  // what Hyprland reads (windows.lua) from the options
  function luaText() {
    return "-- written by the Shell Manager › Windows (WindowsService.qml)\nreturn {\n"
      + ["gapsIn", "gapsOut", "mfact", "columnWidth", "borders", "shadows"].map(k => "\t" + k + " = " + opts[k] + ",\n").join("")
      + ["newStatus", "arrange", "scrollKeys"].map(k => "\t" + k + " = \"" + opts[k] + "\",\n").join("") + "}\n";
  }

  // options written by someone else (About › Settings import / reset): Hyprland gets them too
  function syncLua() {
    luaFile.reload();
    if (luaFile.text() !== luaText()) Hypr.writeState(stateDir + "windows.lua", luaText(), "hyprctl reload");
  }

  FileView {
    id: luaFile
    path: root.stateDir + "windows.lua"
    blockLoading: true
    printErrors: false
  }

  FileView {
    path: root.stateDir + "windows.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoaded: Qt.callLater(root.syncLua)

    JsonAdapter {
      id: opts
      property int gapsIn: 10
      property int gapsOut: 20
      property real mfact: 0.5
      property string newStatus: "slave"      // master | slave: where a new window goes
      property real columnWidth: 0.5          // scrolling: a new column's share
      property string arrange: "cascade"      // floating: cascade | grid | center
      property string scrollKeys: "wheel"     // wheel binds on: wheel | arrows | both
      property bool borders: true             // the windows' frames
      property bool shadows: true
      property bool taskbar: true             // floating: the taskbar along the bottom
      property string taskbarShape: "strip"   // floating taskbar: strip | island (a pill, as the island)
      property bool switcher: true            // floating: Alt+Tab is the window switcher
    }
  }

  // floating: every window of the workspace in a grid (windowmode.lua)
  function arrangeGrid() { Hypr.call("ArrangeGrid()"); }

  // the taskbar's actions; minimized windows wait on special:minimized (windowmode.lua)
  function minimize(address) { Hypr.call("MinimizeWindow(" + (address ? "\"" + address + "\"" : "") + ")"); }
  function restore(address) { Hypr.call("RestoreWindow(\"" + address + "\")"); }
  function close(address) { Hypr.call("hl.dispatch(hl.dsp.window.close({ window = \"address:" + address + "\" }))"); }

  // the launcher switches the mode: `ipc call windowmode set floating`
  // ("windows" is the bar popup's)
  IpcHandler {
    target: "windowmode"
    function set(value: string): void { if (root.modes.some(m => m.value === value)) root.setMode(value); }
  }

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
