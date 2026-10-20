pragma Singleton
import QtQuick

// Colors — kanagawa-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#f2ecbc"
  readonly property color background1: "#e5ddb0"
  readonly property color background2: "#dcd5ac"
  readonly property color background3: "#d5cea3"

  // foregrounds
  readonly property color foreground0: "#545464"
  readonly property color foreground1: "#43436c"
  readonly property color foreground2: "#6a6a7a"

  // accents
  readonly property color red:    "#c84053"
  readonly property color orange: "#cc6d00"
  readonly property color yellow: "#77713f"
  readonly property color green:  "#6f894e"
  readonly property color aqua:   "#597b75"
  readonly property color blue:   "#4d699b"
  readonly property color purple: "#624c83"
  readonly property color gray:   "#a09c86"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#6b685a"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#624c83"
  readonly property color dim:    "#c4bf9c"   // kitty color0
}