pragma Singleton
import QtQuick

// Colors — gruvbox palette overlay (same values as the base copy in
// packages/quickshell/taskbar/config/Colors.qml).

QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#202020"
  readonly property color background1: "#32302f"
  readonly property color background2: "#3c3836"
  readonly property color background3: "#45403d"

  // foregrounds
  readonly property color foreground0: "#d4be98"
  readonly property color foreground1: "#ddc7a1"
  readonly property color foreground2: "#bdae93"

  // accents
  readonly property color red:    "#ea6962"
  readonly property color orange: "#e78a4e"
  readonly property color yellow: "#d8a657"
  readonly property color green:  "#a9b665"
  readonly property color aqua:   "#89b482"
  readonly property color blue:   "#7daea3"
  readonly property color purple: "#d3869b"
  readonly property color gray:   "#7c6f64"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#928374"   // color8 — disconnected / secondary

  // hyprland frame (packages/hypr/components/appearance.lua: border_size, active_border)
  readonly property color frame:  "#282828"   // active_border (background_alt)
  readonly property color dim:    "#665c54"   // rofi `fg` (kitty color0)

  // workspace labels: "{name}" shows names, "{icon}" the icons below.
  readonly property string workspaceFormat: "{name}"     // "{name}" | "{icon}"
  readonly property string workspaceIconDefault: ""      // used when format = "{icon}"
  readonly property string workspaceIconActive: ""       // used when format = "{icon}"
}