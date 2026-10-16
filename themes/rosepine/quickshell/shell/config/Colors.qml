pragma Singleton
import QtQuick

// Colors — rosepine theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#191724"
  readonly property color background1: "#1f1d2e"
  readonly property color background2: "#26233a"
  readonly property color background3: "#403d52"

  // foregrounds
  readonly property color foreground0: "#e0def4"
  readonly property color foreground1: "#f0eefc"
  readonly property color foreground2: "#c1bed9"

  // accents
  readonly property color red:    "#eb6f92"
  readonly property color orange: "#ea9a97"
  readonly property color yellow: "#f6c177"
  readonly property color green:  "#a3c9a0"
  readonly property color aqua:   "#9ccfd8"
  readonly property color blue:   "#7aa6c2"
  readonly property color purple: "#c4a7e7"
  readonly property color gray:   "#6e6a86"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#908caa"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#c4a7e7"
  readonly property color dim:    "#524f67"   // kitty color0
}