import QtQuick
import QtQuick.Effects
import qs.config

// An SVG icon from kit/icons, recoloured to `tint`. The files are drawn in
// white (Lucide-style outlines, square caps), so colorization maps them to any
// theme colour exactly. `solid` (the user's icon style, Shell Manager ›
// Appearance, unless set) picks the filled variant from icons/solid, falling
// back to the outline when there is none — line glyphs (check, x, arrows) have
// nothing to fill, and heart / heart-filled carry meaning (liked or not).
Item {
  id: root

  property string name: ""
  property color tint: Theme.foreground0
  property int size: Theme.fontSize + 3
  property bool solid: ShellSettings.solidIcons
  property bool round: ShellSettings.roundIcons   // soft corners: icons/round (kit/icons/mkround.py)

  // names that have a filled variant in icons/solid
  readonly property var solidNames: ["app-window", "battery-charging", "battery", "bell", "bot", "brush", "camera", "circle", "clipboard", "clock", "columns", "cpu", "cursor", "folder", "grid", "headphones", "info", "keyboard", "laptop", "layout", "leaf", "lock", "message", "mic", "monitor", "moon", "music", "pause", "play", "plug", "radio", "server", "settings", "shield", "skip-back", "skip-forward", "sliders", "speaker", "square", "sun", "trash", "video", "volume", "volume-x", "wifi-off", "wifi", "zap"]
  readonly property bool useSolid: solid && solidNames.includes(name)

  implicitWidth: size
  implicitHeight: size

  Image {
    id: image
    anchors.fill: parent
    source: root.name === "" ? ""
      : Qt.resolvedUrl("icons/" + (root.round ? "round/" : "") + (root.useSolid ? "solid/" : "") + root.name + ".svg")
    sourceSize { width: root.size * 2; height: root.size * 2 }
    smooth: true
    visible: false
  }

  MultiEffect {
    anchors.fill: parent
    source: image
    colorization: 1
    colorizationColor: root.tint
  }
}
