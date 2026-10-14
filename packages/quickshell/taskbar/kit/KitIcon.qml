import QtQuick
import QtQuick.Effects
import qs.config

// An SVG icon from kit/icons, recoloured to `tint`. The files are drawn in
// white (Lucide-style outlines, square caps), so colorization maps them to any
// palette colour exactly. `solid` picks the filled variant from icons/solid,
// falling back to the outline when there is none.
Item {
  id: root

  property string name: ""
  property color tint: Theme.foreground0
  property int size: Theme.fontSize + 3
  property bool solid: false

  // names that have a filled variant in icons/solid
  readonly property var solidNames: ["battery-charging", "battery", "bell", "bot", "clock", "grid", "headphones", "keyboard", "leaf", "moon", "music", "plug", "radio", "shield", "sliders", "sun", "volume", "volume-x", "wifi-off", "wifi"]
  readonly property bool useSolid: solid && solidNames.includes(name)

  implicitWidth: size
  implicitHeight: size

  Image {
    id: image
    anchors.fill: parent
    source: root.name === "" ? ""
      : Qt.resolvedUrl((root.useSolid ? "icons/solid/" : "icons/") + root.name + ".svg")
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
