pragma Singleton
import QtQuick

// Colors — mono-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#ffffff"
  readonly property color background1: "#f3f3f3"
  readonly property color background2: "#e8e8e8"
  readonly property color background3: "#dadada"

  // foregrounds
  readonly property color foreground0: "#111111"
  readonly property color foreground1: "#000000"
  readonly property color foreground2: "#3a3a3a"

  // accents
  readonly property color red:    "#8f4f4f"
  readonly property color orange: "#8f6a4f"
  readonly property color yellow: "#7d7440"
  readonly property color green:  "#4f6e4f"
  readonly property color aqua:   "#4a6e69"
  readonly property color blue:   "#4f6587"
  readonly property color purple: "#6c5a85"
  readonly property color gray:   "#9e9e9e"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#5f5f5f"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#737373"
  readonly property color dim:    "#c4c4c4"   // kitty color0
}