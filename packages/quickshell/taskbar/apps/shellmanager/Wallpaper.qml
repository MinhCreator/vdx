import QtQuick
import Quickshell
import Quickshell.Io
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
    // a picture that is gone falls back to the colour
    const set = image === "" ? "awww clear " + hex
      : "awww img --transition-type fade --transition-duration 0.6 \"$HOME/.dotfiles/wallpapers/"
        + image.replace(/"/g, "") + "\" 2>/dev/null || awww clear " + hex;
    proc.running = false;
    proc.command = ["bash", "-c",
      "for i in $(seq 1 25); do awww query >/dev/null 2>&1 && { " + set + "; exit 0; }; sleep 0.4; done; exit 1"];
    proc.running = true;
  }

  onKeyChanged: apply()
  Component.onCompleted: apply()

  Process { id: proc }
}
