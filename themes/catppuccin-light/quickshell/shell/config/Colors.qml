pragma Singleton
import QtQuick

// Colors — catppuccin-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#eff1f5"
  readonly property color background1: "#e6e9ef"
  readonly property color background2: "#dce0e8"
  readonly property color background3: "#ccd0da"

  // foregrounds
  readonly property color foreground0: "#4c4f69"
  readonly property color foreground1: "#2b2d42"
  readonly property color foreground2: "#5c5f77"

  // accents
  readonly property color red:    "#d20f39"
  readonly property color orange: "#fe640b"
  readonly property color yellow: "#df8e1d"
  readonly property color green:  "#40a02b"
  readonly property color aqua:   "#179299"
  readonly property color blue:   "#1e66f5"
  readonly property color purple: "#8839ef"
  readonly property color gray:   "#9ca0b0"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#5c5f77"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#8839ef"
  readonly property color dim:    "#bcc0cc"   // kitty color0
}