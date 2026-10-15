pragma Singleton
import QtQuick

// Colors — graphite theme overlay (same values as the base copy in
// packages/quickshell/shell/config/Colors.qml).

QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#0e0e0e"
  readonly property color background1: "#171717"
  readonly property color background2: "#1f1f1f"
  readonly property color background3: "#2c2c2c"

  // foregrounds
  readonly property color foreground0: "#e4e4e4"
  readonly property color foreground1: "#f2f2f2"
  readonly property color foreground2: "#b8b8b8"

  // accents
  readonly property color red:    "#f07178"
  readonly property color orange: "#f4a261"
  readonly property color yellow: "#e9d16c"
  readonly property color green:  "#7fd1a8"
  readonly property color aqua:   "#5fc4d4"
  readonly property color blue:   "#6aa7f0"
  readonly property color purple: "#b39ddb"
  readonly property color gray:   "#6e6e6e"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#8a8a8a"   // color8 — disconnected / secondary

  // popup frame (and mako / rofi frames); controls use `gray`
  readonly property color frame:  "#a0a0a0"
  readonly property color dim:    "#4f4f4f"   // rofi `fg` (kitty color0)

  // workspace labels: "{name}" shows names, "{icon}" the icons below.
  readonly property string workspaceFormat: "{name}"     // "{name}" | "{icon}"
  readonly property string workspaceIconDefault: ""      // used when format = "{icon}"
  readonly property string workspaceIconActive: ""       // used when format = "{icon}"
}