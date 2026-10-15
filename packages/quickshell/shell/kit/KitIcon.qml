import QtQuick
import QtQuick.Effects
import qs.config

// An SVG icon from kit/icons (Material Symbols), recoloured to `tint`. The
// files are drawn in white, so colorization maps them to any theme colour.
// `solid` (the user's icon style, Shell Manager › Appearance, unless set) picks
// the filled variant from icons/solid.
Item {
  id: root

  property string name: ""
  property color tint: Theme.foreground0
  property int size: Theme.fontSize + 3
  property bool solid: ShellSettings.solidIcons

  readonly property bool useSolid: solid

  implicitWidth: size
  implicitHeight: size

  Image {
    id: image
    anchors.fill: parent
    source: root.name === "" ? ""
      : Qt.resolvedUrl("icons/" + (root.useSolid ? "solid/" : "") + root.name + ".svg")
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
