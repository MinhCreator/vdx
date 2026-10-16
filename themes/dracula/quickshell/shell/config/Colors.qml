pragma Singleton
import QtQuick

// Colors — dracula theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#282a36"
  readonly property color background1: "#2f3241"
  readonly property color background2: "#383a4a"
  readonly property color background3: "#44475a"

  // foregrounds
  readonly property color foreground0: "#f8f8f2"
  readonly property color foreground1: "#fafaf5"
  readonly property color foreground2: "#c9c9c4"

  // accents
  readonly property color red:    "#ff5555"
  readonly property color orange: "#ffb86c"
  readonly property color yellow: "#f1fa8c"
  readonly property color green:  "#50fa7b"
  readonly property color aqua:   "#8be9fd"
  readonly property color blue:   "#8094ff"
  readonly property color purple: "#bd93f9"
  readonly property color gray:   "#6272a4"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#7a86b0"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#bd93f9"
  readonly property color dim:    "#4d5168"   // kitty color0
}