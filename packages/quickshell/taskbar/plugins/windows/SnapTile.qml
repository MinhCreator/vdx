import QtQuick
import qs.config

// One snap target: a tiny screen with the part the window will take filled
// (`area`: x, y, width, height as shares). Hover lights it, a click picks it.
Rectangle {
  id: root

  property var area: [0, 0, 1, 1]
  property string tip: ""

  signal picked()

  width: 46
  height: 30
  color: area_.containsMouse ? Theme.background1 : "transparent"
  border.width: 1
  border.color: area_.containsMouse ? Theme.foreground2 : Theme.gray

  Rectangle {
    x: 4 + root.area[0] * (root.width - 8) + (root.area[0] > 0 ? 1 : 0)
    y: 4 + root.area[1] * (root.height - 8) + (root.area[1] > 0 ? 1 : 0)
    width: root.area[2] * (root.width - 8) - (root.area[0] > 0 ? 1 : 0) - (root.area[0] + root.area[2] < 0.999 ? 1 : 0)
    height: root.area[3] * (root.height - 8) - (root.area[1] > 0 ? 1 : 0) - (root.area[1] + root.area[3] < 0.999 ? 1 : 0)
    color: area_.containsMouse ? Theme.foreground0 : Theme.foreground2
  }

  MouseArea {
    id: area_
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.picked()
  }
}
