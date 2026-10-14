import QtQuick
import QtQuick.Effects
import qs.config

// An SVG icon from kit/icons, recoloured to `tint`. The files are drawn in
// white (Lucide-style outlines, square caps), so colorization maps them to any
// palette colour exactly.
Item {
  id: root

  property string name: ""
  property color tint: Theme.foreground0
  property int size: Theme.fontSize + 3

  implicitWidth: size
  implicitHeight: size

  Image {
    id: image
    anchors.fill: parent
    source: root.name !== "" ? Qt.resolvedUrl("icons/" + root.name + ".svg") : ""
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
