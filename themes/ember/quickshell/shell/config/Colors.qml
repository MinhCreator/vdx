pragma Singleton
import QtQuick

// Colors — ember theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#231b19"
  readonly property color background1: "#2c2220"
  readonly property color background2: "#352925"
  readonly property color background3: "#42322c"

  // foregrounds
  readonly property color foreground0: "#eadbd0"
  readonly property color foreground1: "#f4e8de"
  readonly property color foreground2: "#bfae9f"

  // accents
  readonly property color red:    "#ff5c57"
  readonly property color orange: "#ff8a5c"
  readonly property color yellow: "#f9c56a"
  readonly property color green:  "#8fd45f"
  readonly property color aqua:   "#5fd3b8"
  readonly property color blue:   "#5ea8ff"
  readonly property color purple: "#e48ad8"
  readonly property color gray:   "#6e5a51"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#94827a"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#e07a5f"
  readonly property color dim:    "#574640"   // kitty color0
}