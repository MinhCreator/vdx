pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

// Window mode and snapping (hypr/components/windowmode.lua does the work):
// tiling, floating (like Windows) or scrolling (like Niri), kept in
// ~/.local/state/dotfiles/window-mode for every Hyprland start; and putting
// the active window on a part of the screen.
Singleton {
  id: root

  readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/dotfiles/window-mode"

  // ---- state ----
  property string mode: "tiling"            // tiling | floating | scrolling
  readonly property var active: Hyprland.activeToplevel

  readonly property var modes: [
    { value: "tiling", label: "Tiling", icon: "layout", about: "windows share the screen side by side" },
    { value: "floating", label: "Floating", icon: "app-window", about: "like Windows: drag and resize freely" },
    { value: "scrolling", label: "Scrolling", icon: "columns", about: "like Niri: a row of columns you scroll" }
  ]

  function setMode(value) {
    if (value === mode) return;
    mode = value;
    // the config reloads: the mode's windows, binds and gestures set from scratch
    run(["bash", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1" && hyprctl reload',
         "_", stateFile, value]);
  }

  // spot: left | right | top | bottom | top-left … | left-third … | center | maximize
  function snap(spot) { run(["hyprctl", "eval", "SnapWindow(\"" + spot + "\")"]); }

  function run(command) { Quickshell.execDetached(command); }

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
