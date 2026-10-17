import QtQuick
import qs.config
import qs.kit

// A round icon button of the island's player: solid glyph, a soft disc on hover.
Rectangle {
  id: root

  property string icon: ""
  property int iconSize: 20

  signal clicked()

  implicitWidth: iconSize + 14
  implicitHeight: iconSize + 14
  radius: Theme.round ? width / 2 : 0
  color: area.containsMouse ? Theme.background1 : "transparent"
  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  KitIcon {
    anchors.centerIn: parent
    name: root.icon
    size: root.iconSize
    solid: true
    scale: area.pressed ? 0.88 : 1
    Behavior on scale { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
