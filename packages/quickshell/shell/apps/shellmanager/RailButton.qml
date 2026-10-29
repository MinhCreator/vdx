import QtQuick
import qs.config
import qs.kit

// A button of the Shell Manager's rail: a group, or a page of the shell's own.
// The icon with its name under it, so nothing needs a tooltip.
Rectangle {
  id: button

  property string icon: ""
  property string label: ""
  property bool active: false

  signal clicked()

  width: 56
  height: 52
  radius: Theme.radiusControl
  Accessible.role: Accessible.Button
  Accessible.name: label
  color: active ? Theme.pickFill : area.containsMouse ? Theme.controlHover : Theme.clear
  Behavior on color { enabled: Motion.pages; ColorAnimation { duration: Motion.quick } }

  Column {
    anchors.centerIn: parent
    spacing: Theme.gapTight

    KitIcon {
      anchors.horizontalCenter: parent.horizontalCenter
      name: button.icon
      size: 18
      tint: button.active ? Theme.foreground0 : Theme.foreground2
    }
    KitText {
      anchors.horizontalCenter: parent.horizontalCenter
      text: button.label
      font.pixelSize: Theme.fontSize - 4
      color: button.active ? Theme.foreground0 : Theme.muted
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: button.clicked()
  }
}
