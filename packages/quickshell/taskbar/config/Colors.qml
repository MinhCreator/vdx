pragma Singleton
import QtQuick

// Colors — colours of the active theme, read through Theme.qml.
//
// This base copy holds the gruvbox colours. A theme replaces the file through
// install.py's overlay (themes/<t>/quickshell/taskbar/config/Colors.qml wins);
// `pragma Singleton` registers it as a singleton.

QtObject {
  id: root

  // backgrounds
  readonly property color background0: "#202020"
  readonly property color background1: "#32302f"
  readonly property color background2: "#3c3836"
  readonly property color background3: "#45403d"

  // foregrounds
  readonly property color foreground0: "#d4be98"
  readonly property color foreground1: "#ddc7a1"
  readonly property color foreground2: "#bdae93"

  // accents
  readonly property color red:    "#ea6962"
  readonly property color orange: "#e78a4e"
  readonly property color yellow: "#d8a657"
  readonly property color green:  "#a9b665"
  readonly property color aqua:   "#89b482"
  readonly property color blue:   "#7daea3"
  readonly property color purple: "#d3869b"
  readonly property color gray:   "#7c6f64"

  // kitty terminal palette (themes/<t>/kitty/colors.conf) — the mihomo status
  // and popup take their colors from here.
  readonly property color muted:  "#928374"   // color8 (bright black) — disconnected / secondary

  // popup frame (and mako / rofi frames); controls use `gray`
  readonly property color frame:  "#7c6f64"
  readonly property color dim:    "#665c54"   // secondary text (rofi `fg`)

  // workspace labels: "{name}" shows names, "{icon}" the icons below.
  readonly property string workspaceFormat: "{name}"     // "{name}" | "{icon}"
  readonly property string workspaceIconDefault: ""      // used when format = "{icon}"
  readonly property string workspaceIconActive: ""       // used when format = "{icon}"
}