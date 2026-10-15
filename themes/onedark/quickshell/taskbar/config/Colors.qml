pragma Singleton
import QtQuick

// Colors — onedark theme overlay (same values as the base copy in
// packages/quickshell/taskbar/config/Colors.qml).

QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#282c34"
  readonly property color background1: "#2c313a"
  readonly property color background2: "#353b45"
  readonly property color background3: "#3e4451"

  // foregrounds
  readonly property color foreground0: "#abb2bf"
  readonly property color foreground1: "#c8ccd4"
  readonly property color foreground2: "#9da5b4"

  // accents
  readonly property color red:    "#e06c75"
  readonly property color orange: "#d19a66"
  readonly property color yellow: "#e5c07b"
  readonly property color green:  "#98c379"
  readonly property color aqua:   "#56b6c2"
  readonly property color blue:   "#61afef"
  readonly property color purple: "#c678dd"
  readonly property color gray:   "#5c6370"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#7f848e"   // color8 — disconnected / secondary

  // popup frame (and mako / rofi frames); controls use `gray`
  readonly property color frame:  "#61afef"
  readonly property color dim:    "#4b5263"   // rofi `fg` (kitty color0)

  // workspace labels: "{name}" shows names, "{icon}" the icons below.
  readonly property string workspaceFormat: "{name}"     // "{name}" | "{icon}"
  readonly property string workspaceIconDefault: ""      // used when format = "{icon}"
  readonly property string workspaceIconActive: ""       // used when format = "{icon}"
}