pragma Singleton
import QtQuick

// Colors — dune palette overlay.
// Mirrors themes/dune/waybar/colors.css + themes/dune/waybar/modules/workspaces.jsonc
// (dune shows workspace *icons* instead of names).

QtObject {
  id: root

  // backgrounds (colors.css)
  readonly property color background0: "#202020"
  readonly property color background1: "#151515"
  readonly property color background2: "#282828"
  readonly property color background3: "#3c3836"

  // foregrounds (colors.css)
  readonly property color foreground0: "#ebdbb2"
  readonly property color foreground1: "#d7c5a7"
  readonly property color foreground2: "#bdae93"

  // accents (colors.css)
  readonly property color red:    "#d67b76"
  readonly property color orange: "#cba364"
  readonly property color yellow: "#cba364"
  readonly property color green:  "#a3ae6d"
  readonly property color aqua:   "#8daf87"
  readonly property color blue:   "#82a9a0"
  readonly property color purple: "#cb8e9e"
  readonly property color gray:   "#867970"

  // kitty terminal palette (themes/dune/kitty/colors.conf)
  readonly property color muted:  "#867970"   // color8 — disconnected / secondary

  // hyprland frame (packages/hypr/components/appearance.lua: border_size, active_border)
  readonly property color frame:  "#282828"   // active_border (background_alt)
  readonly property color dim:    "#867970"   // rofi `fg` (kitty color0)

  // theme-specific module values — mirrors themes/<t>/waybar/modules/*.jsonc:
  // dune workspaces.jsonc uses format "{icon}" with default 󰧞 / active 󱘹.
  readonly property string workspaceFormat: "{icon}"     // "{name}" | "{icon}"
  readonly property string workspaceIconDefault: "󰧞"   // U+F09DE
  readonly property string workspaceIconActive: "󱘹"    // U+F1639
}