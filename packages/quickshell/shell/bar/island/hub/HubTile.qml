import QtQuick
import qs.config
import qs.kit

// One tile of the hub: a round icon (white when on, dark when off), the name,
// a detail line and a chevron. A click is the tile's own action.
Rectangle {
  id: root

  property string icon: ""
  property string title: ""
  property string detail: ""
  property bool on: false

  signal clicked()

  implicitHeight: 64
  radius: 22
  color: area.containsMouse ? Theme.background2 : Theme.background1

  Rectangle {
    id: disc
    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
    width: 40; height: 40; radius: 20
    color: root.on ? Theme.foreground1 : Theme.background3
    KitIcon { anchors.centerIn: parent; name: root.icon; size: 18; tint: root.on ? Theme.background0 : Theme.foreground2 }
  }

  Column {
    anchors { left: disc.right; leftMargin: 12; right: chevron.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
    spacing: 1
    KitText { width: parent.width; text: root.title; font.pixelSize: 14; font.weight: Font.Medium; elide: Text.ElideRight }
    KitText { width: parent.width; text: root.detail; color: Theme.muted; font.pixelSize: 11; elide: Text.ElideRight }
  }

  KitIcon {
    id: chevron
    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
    name: "chevron-right"
    size: 12
    tint: Theme.dim
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
