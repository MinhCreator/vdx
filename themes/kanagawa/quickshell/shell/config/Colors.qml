pragma Singleton
import QtQuick

// Colors — kanagawa theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#1f1f28"
  readonly property color background1: "#2a2a37"
  readonly property color background2: "#363646"
  readonly property color background3: "#54546d"

  // foregrounds
  readonly property color foreground0: "#dcd7ba"
  readonly property color foreground1: "#eae6cb"
  readonly property color foreground2: "#c8c093"

  // accents
  readonly property color red:    "#e46876"
  readonly property color orange: "#ffa066"
  readonly property color yellow: "#e6c384"
  readonly property color green:  "#98bb6c"
  readonly property color aqua:   "#7aa89f"
  readonly property color blue:   "#7e9cd8"
  readonly property color purple: "#957fb8"
  readonly property color gray:   "#727169"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#938aa9"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#7e9cd8"
  readonly property color dim:    "#4a4a5e"   // kitty color0
}