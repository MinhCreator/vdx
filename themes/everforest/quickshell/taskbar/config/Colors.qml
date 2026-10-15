pragma Singleton
import QtQuick

// Colors — everforest theme overlay (same values as the base copy in
// packages/quickshell/taskbar/config/Colors.qml).

QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#2d353b"
  readonly property color background1: "#343f44"
  readonly property color background2: "#3d484d"
  readonly property color background3: "#475258"

  // foregrounds
  readonly property color foreground0: "#d3c6aa"
  readonly property color foreground1: "#e2d7bc"
  readonly property color foreground2: "#bdb59c"

  // accents
  readonly property color red:    "#e67e80"
  readonly property color orange: "#e69875"
  readonly property color yellow: "#dbbc7f"
  readonly property color green:  "#a7c080"
  readonly property color aqua:   "#83c092"
  readonly property color blue:   "#7fbbb3"
  readonly property color purple: "#d699b6"
  readonly property color gray:   "#7a8478"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#859289"   // color8 — disconnected / secondary

  // popup frame (and mako / rofi frames); controls use `gray`
  readonly property color frame:  "#a7c080"
  readonly property color dim:    "#56635f"   // rofi `fg` (kitty color0)

  // workspace labels: "{name}" shows names, "{icon}" the icons below.
  readonly property string workspaceFormat: "{name}"     // "{name}" | "{icon}"
  readonly property string workspaceIconDefault: ""      // used when format = "{icon}"
  readonly property string workspaceIconActive: ""       // used when format = "{icon}"
}