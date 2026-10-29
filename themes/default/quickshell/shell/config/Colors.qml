pragma Singleton
import QtQuick

// Colors — default theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#161618"
  readonly property color background1: "#1e1e21"
  readonly property color background2: "#27272b"
  readonly property color background3: "#34343a"

  // foregrounds
  readonly property color foreground0: "#e6e6e9"
  readonly property color foreground1: "#ffffff"
  readonly property color foreground2: "#b4b4ba"

  // accents
  readonly property color red:    "#f07178"
  readonly property color orange: "#f4a261"
  readonly property color yellow: "#e9d16c"
  readonly property color green:  "#7fd1a8"
  readonly property color aqua:   "#5fc4d4"
  readonly property color blue:   "#6aa7f0"
  readonly property color purple: "#b39ddb"
  readonly property color gray:   "#4a4a52"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#84848c"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#84848c"
  readonly property color dim:    "#3c3c42"   // kitty color0
}