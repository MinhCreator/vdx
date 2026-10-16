pragma Singleton
import QtQuick

// Colors — catppuccin theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#1e1e2e"
  readonly property color background1: "#2a2b3d"
  readonly property color background2: "#313244"
  readonly property color background3: "#45475a"

  // foregrounds
  readonly property color foreground0: "#cdd6f4"
  readonly property color foreground1: "#dfe5fb"
  readonly property color foreground2: "#bac2de"

  // accents
  readonly property color red:    "#f38ba8"
  readonly property color orange: "#fab387"
  readonly property color yellow: "#f9e2af"
  readonly property color green:  "#a6e3a1"
  readonly property color aqua:   "#94e2d5"
  readonly property color blue:   "#89b4fa"
  readonly property color purple: "#cba6f7"
  readonly property color gray:   "#6c7086"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#7f849c"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#cba6f7"
  readonly property color dim:    "#585b70"   // kitty color0
}