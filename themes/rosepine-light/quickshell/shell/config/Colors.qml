pragma Singleton
import QtQuick

// Colors — rosepine-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#faf4ed"
  readonly property color background1: "#f2e9e1"
  readonly property color background2: "#dfdad9"
  readonly property color background3: "#cecacd"

  // foregrounds
  readonly property color foreground0: "#575279"
  readonly property color foreground1: "#464261"
  readonly property color foreground2: "#797593"

  // accents
  readonly property color red:    "#b4637a"
  readonly property color orange: "#d7827e"
  readonly property color yellow: "#ea9d34"
  readonly property color green:  "#5f8a6b"
  readonly property color aqua:   "#56949f"
  readonly property color blue:   "#286983"
  readonly property color purple: "#907aa9"
  readonly property color gray:   "#9893a5"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#68637f"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#907aa9"
  readonly property color dim:    "#b4b0bd"   // kitty color0
}