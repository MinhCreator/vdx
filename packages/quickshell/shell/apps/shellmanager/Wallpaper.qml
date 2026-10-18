import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config

// Wallpaper through awww: the active theme's picture from ~/.dotfiles/wallpapers
// (image mode, one per theme), else a solid colour — the theme's background1
// (a step above the bar) or the user's own from the Shell Manager. Re-applied
// when any of it changes; at login it waits for awww-daemon to come up.
Scope {
  id: root

  readonly property color target: ShellSettings.wallpaperMode === "custom"
    ? ShellSettings.wallpaperColor : Theme.background1
  readonly property string hex: String(target).slice(1, 7)
  readonly property string image: ShellSettings.wallpaperMode === "image"
    ? WallpaperService.imageFor(ThemeService.current) : ""
  readonly property string key: image !== "" ? image : hex

  function apply() {
    // $1 is the picture ("" for the colour), $2 the colour; a picture that is gone
    // falls back to it. A file name never reaches the shell as code.
    const script = 'set_bg() { if [ -n "$1" ]; then awww img --transition-type fade --transition-duration 0.6 "$1" 2>/dev/null || awww clear "$2"; else awww clear "$2"; fi; }; '
      + 'for i in $(seq 1 25); do awww query >/dev/null 2>&1 && { set_bg "$1" "$2"; exit 0; }; sleep 0.4; done; exit 1';
    proc.running = false;
    proc.command = ["bash", "-c", script, "bash", image === "" ? "" : WallpaperService.dir + "/" + image, hex];
    proc.running = true;
  }

  onKeyChanged: apply()
  Component.onCompleted: apply()

  // a monitor plugged in later has no picture yet (awww sets only the outputs
  // it knows of): apply again once it is up, else it shows Hyprland's default
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name.startsWith("monitoradded")) addedTimer.restart();
    }
  }
  Timer { id: addedTimer; interval: 500; onTriggered: root.apply() }

  Process { id: proc }
}
