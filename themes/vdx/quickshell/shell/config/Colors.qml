pragma Singleton
import QtQuick

// Colors — vdx theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#0e0e10"
  readonly property color background1: "#151518"
  readonly property color background2: "#19191c"
  readonly property color background3: "#222226"

  // foregrounds
  readonly property color foreground0: "#ececee"
  readonly property color foreground1: "#f2f2f4"
  readonly property color foreground2: "#a3a3ab"

  // accents
  readonly property color red:    "#ff6b63"
  readonly property color orange: "#f59e6b"
  readonly property color yellow: "#f5b13d"
  readonly property color green:  "#4ade9a"
  readonly property color aqua:   "#5fd3c8"
  readonly property color blue:   "#7db1ff"
  readonly property color purple: "#b79cff"
  readonly property color gray:   "#3a3a40"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#8b8b93"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#3a3a40"
  readonly property color dim:    "#6e6e76"   // kitty color0
}