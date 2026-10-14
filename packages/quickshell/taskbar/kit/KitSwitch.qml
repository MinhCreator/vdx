import QtQuick
import qs.config

// Rectangular switch with a square knob: dim on the left when off, bright on
// the right when on.
Rectangle {
  id: root

  property bool checked: false
  property bool disabled: false

  signal toggled()

  implicitWidth: 36
  implicitHeight: 20
  color: Theme.background3
  border.width: area.containsMouse && !disabled ? Theme.frameWidth : 0
  border.color: Theme.foreground2
  opacity: disabled ? 0.4 : 1

  Rectangle {
    width: 14
    height: 14
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? root.width - width - 3 : 3
    color: root.checked ? Theme.foreground0 : Theme.gray

    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (!root.disabled) root.toggled()
  }
}
