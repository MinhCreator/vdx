import QtQuick
import qs.config
import qs.kit

// A page's row in the Shell Manager's sidebar: icon and name, the open page
// marked. `entry` is the section ({value, label, icon}), `current` the open page.
Rectangle {
  id: row

  property var entry
  property string current: ""
  property bool indent: false      // a child page (the island's Hub, Live activities)
  readonly property bool active: entry.value === current

  signal picked()

  height: Theme.navigationHeight
  radius: Theme.radiusControl
  activeFocusOnTab: true
  Accessible.role: Accessible.Button
  Accessible.name: entry.label
  Accessible.description: active ? "Current page" : ""
  Accessible.onPressAction: picked()
  Keys.onReturnPressed: picked()
  Keys.onSpacePressed: picked()
  border.width: activeFocus ? Theme.focusWidth : 0
  border.color: Theme.focusRing
  color: active ? Theme.pickFill : area.containsMouse || activeFocus ? Theme.controlHover : Theme.clear
  Behavior on color { enabled: Motion.pages; ColorAnimation { duration: Motion.quick } }

  KitIcon {
    id: icon
    anchors { left: parent.left; leftMargin: Theme.gapLoose + (row.indent ? Theme.gapWide : 0); verticalCenter: parent.verticalCenter }
    name: row.entry.icon
    tint: row.active ? Theme.foreground0 : Theme.foreground2
    size: 16
  }

  KitText {
    anchors { left: icon.right; leftMargin: Theme.gapLoose; right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
    text: row.entry.label
    elide: Text.ElideRight
    color: row.active ? Theme.foreground0 : Theme.foreground2
    font.weight: row.active ? Theme.pickWeight : Font.Normal
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: row.active ? Qt.ArrowCursor : Qt.PointingHandCursor
    onClicked: row.picked()
  }
}
