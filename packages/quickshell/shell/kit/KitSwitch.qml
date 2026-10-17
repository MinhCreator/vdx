import QtQuick
import qs.config

// Rectangular switch with a square knob (round corners: a pill and a disc):
// dim on the left when off, bright on the right when on.
Rectangle {
  id: root

  property bool checked: false
  property bool disabled: false
  property color trackColor: Theme.background3   // darker on a filled (selected) row

  signal toggled()

  implicitWidth: 36
  implicitHeight: 20
  radius: Theme.pill(height)
  color: root.trackColor
  border.width: area.containsMouse && !disabled ? Theme.frameWidth : 0
  border.color: Theme.foreground2
  opacity: disabled ? 0.4 : 1

  Rectangle {
    width: 14
    height: 14
    radius: Theme.pill(height)
    anchors.verticalCenter: parent.verticalCenter
    x: root.checked ? root.width - width - 3 : 3
    color: root.checked ? Theme.foreground0 : Theme.gray

    Behavior on x { enabled: Motion.controls; NumberAnimation { duration: Motion.quick; easing.type: Motion.easing } }
    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (!root.disabled) root.toggled()
  }
}
