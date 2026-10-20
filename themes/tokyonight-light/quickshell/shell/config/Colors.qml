pragma Singleton
import QtQuick

// Colors — tokyonight-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#e1e2e7"
  readonly property color background1: "#d5d6db"
  readonly property color background2: "#c4c8da"
  readonly property color background3: "#b6bfe2"

  // foregrounds
  readonly property color foreground0: "#3760bf"
  readonly property color foreground1: "#2e3c64"
  readonly property color foreground2: "#6172b0"

  // accents
  readonly property color red:    "#f52a65"
  readonly property color orange: "#b15c00"
  readonly property color yellow: "#8c6c3e"
  readonly property color green:  "#587539"
  readonly property color aqua:   "#118c74"
  readonly property color blue:   "#2e7de9"
  readonly property color purple: "#9854f1"
  readonly property color gray:   "#8990b3"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#4f5a8a"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#2e7de9"
  readonly property color dim:    "#a8aecb"   // kitty color0
}