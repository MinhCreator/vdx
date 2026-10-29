pragma Singleton
import QtQuick

// Colors — default-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#f7f7f8"
  readonly property color background1: "#eeeef0"
  readonly property color background2: "#e4e4e7"
  readonly property color background3: "#d6d6db"

  // foregrounds
  readonly property color foreground0: "#1c1c1f"
  readonly property color foreground1: "#000000"
  readonly property color foreground2: "#46464d"

  // accents
  readonly property color red:    "#c4384a"
  readonly property color orange: "#c2671c"
  readonly property color yellow: "#9a7b0f"
  readonly property color green:  "#2f8a5a"
  readonly property color aqua:   "#1f8a99"
  readonly property color blue:   "#2f6fc4"
  readonly property color purple: "#7b5cc0"
  readonly property color gray:   "#a0a0a8"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#62626a"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#5e5e66"
  readonly property color dim:    "#c2c2c8"   // kitty color0
}