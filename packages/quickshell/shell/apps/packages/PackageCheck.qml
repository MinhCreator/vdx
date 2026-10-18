import QtQuick
import qs.config
import qs.kit

// A checkbox for the package lists: a square outline; a check when picked, a
// bar when only some of a group are (`partial`). A control: its frame and fill
// follow Appearance › Controls.
Rectangle {
  id: root

  property bool checked: false
  property bool partial: false
  signal toggled()

  width: 16
  height: 16
  radius: Math.min(Theme.radiusControl, 4)
  color: checked || partial ? Theme.background3 : Theme.controlFill
  border.width: Theme.frameWidth
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
