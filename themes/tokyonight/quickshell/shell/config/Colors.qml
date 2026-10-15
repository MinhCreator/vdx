pragma Singleton
import QtQuick

// Colors — tokyonight theme overlay (same values as the base copy in
// packages/quickshell/shell/config/Colors.qml).
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#1a1b26"
  readonly property color background1: "#1f2335"
  readonly property color background2: "#24283b"
  readonly property color background3: "#2f344e"

  // foregrounds
  readonly property color foreground0: "#c0caf5"
  readonly property color foreground1: "#d5dcfa"
  readonly property color foreground2: "#a9b1d6"

  // accents
  readonly property color red:    "#f7768e"
  readonly property color orange: "#ff9e64"
  readonly property color yellow: "#e0af68"
  readonly property color green:  "#9ece6a"
  readonly property color aqua:   "#73daca"
  readonly property color blue:   "#7aa2f7"
  readonly property color purple: "#bb9af7"
  readonly property color gray:   "#565f89"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#737aa2"   // color8 — disconnected / secondary

  // popup frame (and mako / rofi frames); controls use `gray`
  readonly property color frame:  "#7aa2f7"
  readonly property color dim:    "#3b4261"   // rofi `fg` (kitty color0)

  // workspace labels: "{name}" shows names, "{icon}" the icons below.
  readonly property string workspaceFormat: "{name}"     // "{name}" | "{icon}"
  readonly property string workspaceIconDefault: ""      // used when format = "{icon}"
  readonly property string workspaceIconActive: ""       // used when format = "{icon}"
}