import QtQuick
import qs.config
import qs.kit

// ".." — the first row of a folder's list or grid, the way up. A double click
// goes to the folder above (a single click only selects nothing); it is gone
// where there is none, and while a search runs.
Rectangle {
  id: root

  // there only where a folder is above (and no search runs): no blank row at the root or in the trash
  readonly property bool active: FilesService.canUp && !FilesService.searching
  width: parent ? parent.width : 0
  height: active ? 28 : 0
  opacity: active ? 1 : 0
  radius: Theme.radiusControl
  color: area.containsMouse ? Theme.controlHover : Theme.clear
  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  // the '..' sits in the icon column, the hint in the name column
  KitText {
    id: dots
    anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
    text: ".."
    font.weight: Font.ExtraBold
  }

  KitText {
    anchors { left: parent.left; leftMargin: Theme.gapLoose + Theme.iconSmall + Theme.gapMedium; verticalCenter: parent.verticalCenter }
    text: "Up"
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    enabled: root.active
    onDoubleClicked: FilesService.up()
  }
}
