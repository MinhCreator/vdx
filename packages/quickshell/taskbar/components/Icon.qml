import QtQuick
import QtQuick.Effects

// A tinted monochrome icon. Loads `source` (svg/png) and re-colors the alpha
// shape with a single `color` — the icon set in taskbar/icons/ is stroke-based
// lucide SVGs (stroke="currentColor"), and QML's Image has no color context,
// so they would render black; here every icon becomes `color`.
Item {
  id: root

  property url source: ""
  property color color: "white"
  property int size: 16

  implicitWidth: root.size
  implicitHeight: root.size

  Image {
    id: src
    anchors.fill: parent
    source: root.source
    sourceSize.width: root.size * 2
    sourceSize.height: root.size * 2
    fillMode: Image.PreserveAspectFit
    smooth: true
    mipmap: true
  }

  // Capture the icon into a texture without drawing the (black) original,
  // then overlay the palette color over its alpha channel.
  ShaderEffectSource {
    id: captured
    anchors.fill: parent
    sourceItem: src
    hideSource: true
    live: true
    smooth: true
  }

  MultiEffect {
    anchors.fill: parent
    source: captured
    saturation: 0
    colorization: 1
    colorizationColor: root.color
  }
}