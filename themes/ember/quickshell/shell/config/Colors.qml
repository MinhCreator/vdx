pragma Singleton
import QtQuick

// Colors — ember theme overlay (same values as the base copy in
// packages/quickshell/shell/config/Colors.qml).

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

  // popup frame (and mako / rofi frames); controls use `gray`
  readonly property color frame:  "#e07a5f"
  readonly property color dim:    "#574640"   // rofi `fg` (kitty color0)

  // workspace labels: "{name}" shows names, "{icon}" the icons below.
  readonly property string workspaceFormat: "{name}"     // "{name}" | "{icon}"
  readonly property string workspaceIconDefault: ""      // used when format = "{icon}"
  readonly property string workspaceIconActive: ""       // used when format = "{icon}"
}