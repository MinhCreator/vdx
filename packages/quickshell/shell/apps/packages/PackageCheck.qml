import QtQuick
import qs.config
import qs.kit

// A checkbox for the package lists: a square outline; a check when picked, a
// bar when only some of a group are (`partial`). Sharp corners.
Rectangle {
  id: root

  property bool checked: false
  property bool partial: false
  signal toggled()

  width: 16
  height: 16
  color: checked || partial ? Theme.background3 : "transparent"
  border.width: 1
  border.color: checked || partial ? Theme.foreground0 : Theme.muted

  KitIcon {
    anchors.centerIn: parent
    visible: root.checked && !root.partial
    name: "check"
    solid: false
    size: 12
    tint: Theme.foreground0
  }

  Rectangle {
    anchors.centerIn: parent
    visible: root.partial
    width: 8
    height: 2
    color: Theme.foreground0
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.toggled()
  }
}
