pragma Singleton
import QtQuick

// Colors — ember-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#faf3ee"
  readonly property color background1: "#f2e7df"
  readonly property color background2: "#e9dcd2"
  readonly property color background3: "#dccabd"

  // foregrounds
  readonly property color foreground0: "#3a2a24"
  readonly property color foreground1: "#2a1d18"
  readonly property color foreground2: "#5c4a42"

  // accents
  readonly property color red:    "#d23b33"
  readonly property color orange: "#c95a28"
  readonly property color yellow: "#a8771c"
  readonly property color green:  "#4f8a2e"
  readonly property color aqua:   "#1f8f7a"
  readonly property color blue:   "#2f6fc4"
  readonly property color purple: "#a8429c"
  readonly property color gray:   "#a8958a"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#6e5a4f"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#e07a5f"
  readonly property color dim:    "#c8b6aa"   // kitty color0
}