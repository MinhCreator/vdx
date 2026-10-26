import QtQuick
import Quickshell.Widgets
import qs.config

// A segmented control: a segment per choice, the one matching `current` picked.
// Model: [{label, value}]. Takes the width it is given (KitRow wide), split evenly.
// Material: the Material 3 segmented button — 40 px, full corners, an outline round
// it and between segments, the picked segment in the secondary container with a check
// (outlined in Filled too: M3 has no filled segmented button). Strict (the boards): a 3 px
// well, the picked segment a raised pill of its own, no check (Outlined: the well framed).
Rectangle {
  id: root

  property var model: []
  property var current: null
  property bool disabled: false

  signal picked(var value)

  readonly property bool m3: Theme.m3
  readonly property int inset: Theme.segmentInset

  implicitWidth: Theme.controlWidth
  implicitHeight: Theme.segmentHeight
  radius: Theme.radiusFor(height)
  color: !m3 && Theme.filled ? Theme.wellFill : Theme.clear
  border.width: m3 || !Theme.filled ? 1 : 0
  border.color: Theme.outline
  opacity: disabled ? Theme.disabledOpacity : 1

  // material: the segments cut to the outline's inside; strict: each segment rounds itself
  ClippingRectangle {
    anchors { fill: parent; margins: root.m3 ? root.border.width : root.inset }
    radius: Math.max(0, root.radius - (root.m3 ? root.border.width : root.inset))
    color: Theme.clear

    Row {
      id: segments
      anchors.fill: parent

      Repeater {
        model: root.model

        Rectangle {
          id: segment

          required property var modelData
          required property int index

          readonly property bool selected: modelData.value === root.current
          readonly property bool hovered: area.containsMouse && !root.disabled && !selected

          width: segments.width / root.model.length
          height: segments.height
          // material: the clip gives the outer corners (a segment's own would notch the joint)
          radius: root.m3 ? 0 : Theme.radiusFor(height)
          color: selected ? Theme.selectedFill : hovered ? Theme.hover(Theme.clear) : Theme.clear

          Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

          // material: a divider between two segments
          Rectangle {
            visible: root.m3 && segment.index > 0
            width: 1
            height: parent.height
            color: Theme.outline
          }

          Row {
            anchors.centerIn: parent
            width: Math.min(implicitWidth, parent.width - Theme.gapMedium)
            spacing: Theme.gapSmall

            KitIcon {
              id: tick
              anchors.verticalCenter: parent.verticalCenter
              visible: root.m3 && segment.selected && segment.width >= label.implicitWidth + 40
              name: "check"
              tint: label.color
              size: Theme.iconControl
            }

            KitText {
              id: label
              anchors.verticalCenter: parent.verticalCenter
              width: Math.min(implicitWidth, segment.width - Theme.gapMedium - (tick.visible ? tick.width + parent.spacing : 0))
              elide: Text.ElideRight
              text: segment.modelData.label
              color: segment.selected ? Theme.accentFor("choices", Theme.selectedText) : Theme.restText
              font.pixelSize: Theme.textControl
              font.weight: segment.selected ? Theme.controlWeight : Theme.restWeight
            }
          }

          MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: if (!root.disabled && !segment.selected) root.picked(segment.modelData.value)
          }
        }
      }
    }
  }
}
