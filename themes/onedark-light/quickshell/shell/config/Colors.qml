pragma Singleton
import QtQuick

// Colors — onedark-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#fafafa"
  readonly property color background1: "#f0f0f1"
  readonly property color background2: "#e5e5e6"
  readonly property color background3: "#dbdbdc"

  // foregrounds
  readonly property color foreground0: "#383a42"
  readonly property color foreground1: "#202227"
  readonly property color foreground2: "#4f525e"

  // accents
  readonly property color red:    "#e45649"
  readonly property color orange: "#986801"
  readonly property color yellow: "#c18401"
  readonly property color green:  "#50a14f"
  readonly property color aqua:   "#0184bc"
  readonly property color blue:   "#4078f2"
  readonly property color purple: "#a626a4"
  readonly property color gray:   "#a0a1a7"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#62656f"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#4078f2"
  readonly property color dim:    "#c2c2c3"   // kitty color0
}