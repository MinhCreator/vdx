import QtQuick
import qs.config

// Nine spots of the screen as a 3 × 3 grid of small cells (top-left …
// bottom-right, the middle one the centre): the chosen one is filled, a click
// picks another. `current` is a spot name or anything else (none filled).
Grid {
  id: root

  property string current: ""
  readonly property var spots: ["top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"]

  signal picked(string spot)

  columns: 3
  spacing: 3

  Repeater {
    model: root.spots

    Rectangle {
      id: cell

      required property string modelData

      readonly property bool active: modelData === root.current

      width: 24
      height: 9
      color: active ? Theme.foreground2 : area.containsMouse ? Theme.background3 : Theme.background1
      border.width: 1
      border.color: active ? Theme.foreground2 : Theme.gray

      MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -1
        hoverEnabled: true
        cursorShape: cell.active ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!cell.active) root.picked(cell.modelData)
      }
    }
  }
}
