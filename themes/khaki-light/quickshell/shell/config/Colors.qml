pragma Singleton
import QtQuick

// Colors — khaki-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#f6f1e4"
  readonly property color background1: "#ede6d4"
  readonly property color background2: "#e3dbc6"
  readonly property color background3: "#d6cbb0"

  // foregrounds
  readonly property color foreground0: "#3a3426"
  readonly property color foreground1: "#26221a"
  readonly property color foreground2: "#5a5240"

  // accents
  readonly property color red:    "#a8473a"
  readonly property color orange: "#a8612e"
  readonly property color yellow: "#8a7020"
  readonly property color green:  "#5e7a3a"
  readonly property color aqua:   "#4f7f6e"
  readonly property color blue:   "#4a6e85"
  readonly property color purple: "#7f5a74"
  readonly property color gray:   "#a39a85"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#6b6250"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#9a947a"
  readonly property color dim:    "#c7bfa9"   // kitty color0
}