pragma Singleton
import QtQuick

// Colors — everforest-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#fdf6e3"
  readonly property color background1: "#f4f0d9"
  readonly property color background2: "#efebd4"
  readonly property color background3: "#e6e2cc"

  // foregrounds
  readonly property color foreground0: "#5c6a72"
  readonly property color foreground1: "#4a555b"
  readonly property color foreground2: "#708089"

  // accents
  readonly property color red:    "#f85552"
  readonly property color orange: "#f57d26"
  readonly property color yellow: "#c78f00"
  readonly property color green:  "#7f9300"
  readonly property color aqua:   "#35a77c"
  readonly property color blue:   "#3a94c5"
  readonly property color purple: "#df69ba"
  readonly property color gray:   "#a6b0a0"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#66756d"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#8da101"
  readonly property color dim:    "#c8c9b5"   // kitty color0
}