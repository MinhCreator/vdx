pragma Singleton
import QtQuick

// Colors — nord-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#eceff4"
  readonly property color background1: "#e5e9f0"
  readonly property color background2: "#d8dee9"
  readonly property color background3: "#c8d0de"

  // foregrounds
  readonly property color foreground0: "#2e3440"
  readonly property color foreground1: "#242933"
  readonly property color foreground2: "#3b4252"

  // accents
  readonly property color red:    "#bf616a"
  readonly property color orange: "#c0673f"
  readonly property color yellow: "#a07a1e"
  readonly property color green:  "#5f8a45"
  readonly property color aqua:   "#4f8f98"
  readonly property color blue:   "#5e81ac"
  readonly property color purple: "#9a6f96"
  readonly property color gray:   "#9aa5b8"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#4c566a"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#5e81ac"
  readonly property color dim:    "#b9c2d2"   // kitty color0
}