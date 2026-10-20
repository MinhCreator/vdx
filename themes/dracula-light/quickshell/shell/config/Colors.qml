pragma Singleton
import QtQuick

// Colors — dracula-light theme overlay: the colours Theme.qml starts with (a theme
// switch reaches it live through ThemeService). Every theme has its copy;
// themes/mktheme.py makes the others from gruvbox's.
QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#fffbeb"
  readonly property color background1: "#f2eedc"
  readonly property color background2: "#e6e2cf"
  readonly property color background3: "#cfcfde"

  // foregrounds
  readonly property color foreground0: "#1f1f1f"
  readonly property color foreground1: "#141414"
  readonly property color foreground2: "#4a4a4a"

  // accents
  readonly property color red:    "#cb3a2a"
  readonly property color orange: "#a34d14"
  readonly property color yellow: "#846e15"
  readonly property color green:  "#14710a"
  readonly property color aqua:   "#036a96"
  readonly property color blue:   "#3557b8"
  readonly property color purple: "#644ac9"
  readonly property color gray:   "#9e9aa8"

  // kitty terminal palette (themes/gruvbox/kitty/colors.conf)
  readonly property color muted:  "#635d97"   // color8 — disconnected / secondary

  // popup frame (and mako's); controls use `gray`
  readonly property color frame:  "#644ac9"
  readonly property color dim:    "#c4c0d0"   // kitty color0
}