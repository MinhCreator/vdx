import QtQuick
import qs.config

// Square on / off switch; the knob slides right when checked.
Item {
  id: root

  property bool checked: false
  property color checkedColor: Theme.green
  property color uncheckedColor: Theme.muted
  property bool disabled: false

  signal toggled()

  implicitWidth: Theme.switchWidth
  implicitHeight: 20
  opacity: disabled ? 0.4 : 1

  Rectangle {
    id: track
    anchors.fill: parent
    color: "transparent"
    border.width: 1
    border.color: area.containsMouse && !root.disabled
      ? (root.checked ? root.checkedColor : root.uncheckedColor)
      : Theme.muted

    Rectangle {
      width: Theme.switchKnob
      height: Theme.switchKnob
      anchors.verticalCenter: parent.verticalCenter
      x: root.checked ? track.width - width - 2 : 2
      color: root.checked ? root.checkedColor : root.uncheckedColor

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
