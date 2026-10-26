import QtQuick
import qs.config

// Outlined button: an optional icon and a label. `selected` fills it in the
// raised tone with a lighter frame and bold text (one of a group of choices).
// `busy` swaps the icon for a spinner. Material: a tonal pill, no frame.
Rectangle {
  id: root

  property string icon: ""               // kit/icons name
  property color iconTint: Theme.foreground0
  property string text: ""
  property bool selected: false
  property bool busy: false
  property bool disabled: false

  readonly property bool hovered: area.containsMouse && !disabled

  signal clicked()

  // an icon alone is a square of the control height
  implicitWidth: text !== "" ? content.implicitWidth + (Theme.material ? 32 : 24) : Theme.controlHeight
  implicitHeight: Theme.controlHeight
  radius: Theme.radiusControl
  // set once: whether it sits in a Settings box (a walk up, not a binding)
  property bool boxed: false
  Component.onCompleted: boxed = Theme.boxed(parent)
  color: selected ? Theme.background3 : hovered ? Theme.hoverOn(boxed) : Theme.fillOn(boxed)
  border.width: Theme.frameWidth
  border.color: selected || hovered ? Theme.outlineActive : Theme.outline
  opacity: disabled ? 0.4 : 1

  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  Behavior on border.color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  Row {
    id: content
    anchors.centerIn: parent
    spacing: Theme.gapMedium

    KitIcon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== "" && !root.busy
      name: root.icon
      tint: root.iconTint
      size: Theme.fontSize + 1
    }

    KitSpinner {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.busy
    }

    KitText {
      visible: root.text !== ""
      text: root.text
      color: root.selected ? Theme.accentFor("choices", Theme.foreground0) : Theme.foreground0
      font.weight: root.selected ? Theme.fontStrong : Font.DemiBold
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    onClicked: if (!root.disabled && !root.busy) root.clicked()
  }
}
