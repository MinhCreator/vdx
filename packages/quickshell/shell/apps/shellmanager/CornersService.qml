pragma Singleton
import QtQuick
import Quickshell
import qs.config

// Appearance › Corners outside the shell: Hyprland's window rounding (now,
// and ~/.local/state/dotfiles/corners.lua for its next start, read by
// hypr/components/appearance.lua) and mako's `round` mode
// (themes/*/mako/config). The shell itself reads Theme's radii.
Singleton {
  id: root

  // ---- tuning ----
  readonly property string stateFile: Quickshell.env("HOME") + "/.local/state/dotfiles/corners.lua"

  readonly property int rounding: Theme.radiusSurface
  onRoundingChanged: apply()

  function apply() {
    const lua = "return { rounding = " + rounding + " }";
    Quickshell.execDetached(["bash", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1"',
                             "_", stateFile, lua]);
    Quickshell.execDetached(["hyprctl", "eval", "hl.config({decoration = {rounding = " + rounding + "}})"]);
    Quickshell.execDetached(["makoctl", "mode", rounding > 0 ? "-a" : "-r", "round"]);
  }
}
