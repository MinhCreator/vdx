import QtQuick

// Square toggle switch for the popup header — square corners, no radius.
// The knob slides left (off) / right (on). Replaces the old power button.
Item {
  id: root

  property bool checked: false
  property color onColor: Theme.green
  property color offColor: Theme.muted
  property bool disabled: false

  readonly property bool hovered: area.containsMouse && !root.disabled

  signal toggled()

  implicitWidth: Theme.switchWidth
  implicitHeight: 20
  opacity: root.disabled ? 0.4 : 1

  Rectangle {
    id: track
    anchors.fill: parent
    color: "transparent"
    border.width: 1
    border.color: root.hovered
      ? (root.checked ? root.onColor : root.offColor)
      : Theme.muted

    Rectangle {
      id: knob
      width: Theme.switchKnob
      height: Theme.switchKnob
      anchors.verticalCenter: parent.verticalCenter
      x: root.checked ? track.width - width - 2 : 2
      color: root.checked ? root.onColor : root.offColor

      Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (!root.disabled) root.toggled()
  }
}
