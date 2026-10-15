pragma Singleton
import QtQuick

// Colors — khaki theme overlay (same values as the base copy in
// packages/quickshell/shell/config/Colors.qml).
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#141414"
  readonly property color background1: "#1b1b1b"
  readonly property color background2: "#232323"
  readonly property color background3: "#322f26"

  // foregrounds
  readonly property color foreground0: "#e5d7b2"
  readonly property color foreground1: "#f0e4c4"
  readonly property color foreground2: "#b8ac8e"

  // accents
  readonly property color red:    "#d47766"
  readonly property color orange: "#d9955b"
  readonly property color yellow: "#dcc07a"
  readonly property color green:  "#a3b37a"
  readonly property color aqua:   "#8fb3a0"
  readonly property color blue:   "#7f9aa8"
  readonly property color purple: "#b391a8"
  readonly property color gray:   "#5a5a5a"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#8a8270"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#9a947a"
  readonly property color dim:    "#464239"   // kitty color0

  // workspace labels: "{name}" shows names, "{icon}" the icons below.
  readonly property string workspaceFormat: "{name}"     // "{name}" | "{icon}"
  readonly property string workspaceIconDefault: ""      // used when format = "{icon}"
  readonly property string workspaceIconActive: ""       // used when format = "{icon}"
}