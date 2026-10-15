pragma Singleton
import QtQuick

// Colors — nord theme overlay (same values as the base copy in
// packages/quickshell/shell/config/Colors.qml).
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#2e3440"
  readonly property color background1: "#3b4252"
  readonly property color background2: "#434c5e"
  readonly property color background3: "#4c566a"

  // foregrounds
  readonly property color foreground0: "#d8dee9"
  readonly property color foreground1: "#eceff4"
  readonly property color foreground2: "#b9c0cd"

  // accents
  readonly property color red:    "#bf616a"
  readonly property color orange: "#d08770"
  readonly property color yellow: "#ebcb8b"
  readonly property color green:  "#a3be8c"
  readonly property color aqua:   "#8fbcbb"
  readonly property color blue:   "#81a1c1"
  readonly property color purple: "#b48ead"
  readonly property color gray:   "#616e88"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#7b88a1"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#88c0d0"
  readonly property color dim:    "#56607a"   // kitty color0

  // workspace labels: "{name}" shows names, "{icon}" the icons below.
  readonly property string workspaceFormat: "{name}"     // "{name}" | "{icon}"
  readonly property string workspaceIconDefault: ""      // used when format = "{icon}"
  readonly property string workspaceIconActive: ""       // used when format = "{icon}"
}