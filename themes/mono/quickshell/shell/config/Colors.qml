pragma Singleton
import QtQuick

// Colors — mono theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#0a0a0a"
  readonly property color background1: "#121212"
  readonly property color background2: "#191919"
  readonly property color background3: "#262626"

  // foregrounds
  readonly property color foreground0: "#d6d6d6"
  readonly property color foreground1: "#f2f2f2"
  readonly property color foreground2: "#a3a3a3"

  // accents
  readonly property color red:    "#c98b8b"
  readonly property color orange: "#c9a78b"
  readonly property color yellow: "#c9c18b"
  readonly property color green:  "#9bb59b"
  readonly property color aqua:   "#8bb3ae"
  readonly property color blue:   "#8ba3c4"
  readonly property color purple: "#ab97c2"
  readonly property color gray:   "#4d4d4d"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#767676"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#8c8c8c"
  readonly property color dim:    "#383838"   // kitty color0
}