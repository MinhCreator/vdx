pragma Singleton
import QtQuick

// Colors — gruvbox-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#fbf1c7"
  readonly property color background1: "#f2e5bc"
  readonly property color background2: "#ebdbb2"
  readonly property color background3: "#d5c4a1"

  // foregrounds
  readonly property color foreground0: "#3c3836"
  readonly property color foreground1: "#282828"
  readonly property color foreground2: "#504945"

  // accents
  readonly property color red:    "#c14a4a"
  readonly property color orange: "#c35e0a"
  readonly property color yellow: "#b47109"
  readonly property color green:  "#6c782e"
  readonly property color aqua:   "#4c7a5d"
  readonly property color blue:   "#45707a"
  readonly property color purple: "#945e80"
  readonly property color gray:   "#a89984"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#6f6259"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#7c6f64"
  readonly property color dim:    "#c9b99a"   // kitty color0
}