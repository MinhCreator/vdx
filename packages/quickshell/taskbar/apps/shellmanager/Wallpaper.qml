import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Solid-colour wallpaper through awww: the theme's background1 (a step above
// the bar) or the user's own colour from the Shell Manager. Re-applied when
// either changes; at login it waits for awww-daemon to come up.
Scope {
  id: root

  readonly property color target: ShellSettings.wallpaperMode === "custom"
    ? ShellSettings.wallpaperColor : Theme.background1
  readonly property string hex: String(target).slice(1, 7)

  function apply() {
    proc.running = false;
    proc.command = ["bash", "-c",
      "for i in $(seq 1 25); do awww clear " + hex + " 2>/dev/null && exit 0; sleep 0.4; done; exit 1"];
    proc.running = true;
  }

  onHexChanged: apply()
  Component.onCompleted: apply()

  Process { id: proc }
}
