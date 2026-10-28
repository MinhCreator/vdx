import QtQuick
import qs.bar.island
import qs.config
import qs.kit

// The hub's head: the date in mono caps, the clock as the hero number, the
// settings and power buttons.
Item {
  id: root

  property date now: new Date()
  signal manager()
  signal power()

  implicitHeight: 90

  Column {
    anchors { left: parent.left; top: parent.top }
    spacing: 2

    KitText {
      text: Qt.formatDateTime(root.now, "dddd · d MMMM").toUpperCase()
      color: Theme.muted
      font.pixelSize: 11
      font.letterSpacing: 0.9
    }
    KitText {
      text: Qt.formatDateTime(root.now, "HH:mm")
      font.pixelSize: 60
      font.letterSpacing: -1.8
      lineHeight: 0.95
    }
  }

  Row {
    anchors { right: parent.right; top: parent.top }
    spacing: 8

    Repeater {
      model: [{ icon: "settings", sig: "manager" }, { icon: "power", sig: "power" }]

      Rectangle {
        required property var modelData
        width: 44
        height: 44
        radius: 22
        color: area.containsMouse ? Theme.background3 : Theme.background2

        KitIcon { anchors.centerIn: parent; name: parent.modelData.icon; size: 18 }
        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: parent.modelData.sig === "manager" ? root.manager() : root.power()
        }
      }
    }
  }
}
