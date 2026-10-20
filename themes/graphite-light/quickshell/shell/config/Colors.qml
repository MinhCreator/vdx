pragma Singleton
import QtQuick

// Colors — graphite-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#f5f5f5"
  readonly property color background1: "#ececec"
  readonly property color background2: "#e2e2e2"
  readonly property color background3: "#d4d4d4"

  // foregrounds
  readonly property color foreground0: "#1c1c1c"
  readonly property color foreground1: "#0a0a0a"
  readonly property color foreground2: "#444444"

  // accents
  readonly property color red:    "#c4384a"
  readonly property color orange: "#c2671c"
  readonly property color yellow: "#9a7b0f"
  readonly property color green:  "#2f8a5a"
  readonly property color aqua:   "#1f8a99"
  readonly property color blue:   "#2f6fc4"
  readonly property color purple: "#7b5cc0"
  readonly property color gray:   "#9a9a9a"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#5f5f5f"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#5c5c5c"
  readonly property color dim:    "#bdbdbd"   // kitty color0
}