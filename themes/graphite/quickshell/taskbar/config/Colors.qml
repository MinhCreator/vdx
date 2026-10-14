pragma Singleton
import QtQuick

// Colors — graphite palette overlay (same values as the base copy in
// packages/quickshell/taskbar/config/Colors.qml).

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
  readonly property color red:    "#e06c6c"
  readonly property color orange: "#d9915a"
  readonly property color yellow: "#d4b866"
  readonly property color green:  "#8fba7a"
  readonly property color aqua:   "#7fb8a8"
  readonly property color blue:   "#82a6c9"
  readonly property color purple: "#b495c9"
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