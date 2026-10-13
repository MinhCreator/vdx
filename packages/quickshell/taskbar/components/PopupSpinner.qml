import QtQuick
import QtQuick.Shapes
import qs.config

// Busy indicator: a 270° arc spinning around the exact centre of its square
// (a font glyph wobbles, its box isn't centred on the drawing). Runs only
// while visible.
Item {
  id: root

  property color tint: Theme.dim
  property real stroke: 2

  implicitWidth: Theme.fontSize - 1
  implicitHeight: implicitWidth

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      strokeColor: root.tint
      strokeWidth: root.stroke
      fillColor: "transparent"
      capStyle: ShapePath.FlatCap

      PathAngleArc {
        centerX: root.width / 2
        centerY: root.height / 2
        radiusX: (root.width - root.stroke) / 2
        radiusY: radiusX
        startAngle: 0
        sweepAngle: 270
      }
    }

    RotationAnimator on rotation {
      running: root.visible
      from: 0
      to: 360
      duration: 800
      loops: Animation.Infinite
    }
  }
}
