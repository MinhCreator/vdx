import QtQuick
import qs.config
import qs.kit

// The box at a row's start (Settings › Checkboxes): ticked while the row is selected; a click toggles
// the row without touching the rest of the selection. `partial`: some rows, not all (the captions' box).
Rectangle {
  id: root

  property bool checked: false
  property bool partial: false
  property bool shown: true             // drawn only while the row is hovered or ticked (the box stays clickable)

  signal toggled()

  width: 16
  height: 16
  radius: Theme.radiusFor(height)
  color: checked || partial ? Theme.foreground0 : Theme.clear
  border.width: checked || partial ? 0 : 1.5
  border.color: area.containsMouse ? Theme.foreground2 : Theme.gray
  opacity: shown || checked || partial || area.containsMouse ? 1 : 0
  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  Behavior on opacity { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }

  KitIcon {
    anchors.centerIn: parent
    visible: root.checked
    name: "check"
    size: 14
    tint: Theme.background0
  }

  Rectangle {
    anchors.centerIn: parent
    visible: root.partial && !root.checked
    width: 8
    height: 2
    color: Theme.background0
  }

  MouseArea {
    id: area
    anchors { fill: parent; margins: -4 }
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}
