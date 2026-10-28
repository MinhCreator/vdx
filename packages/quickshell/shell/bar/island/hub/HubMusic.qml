import QtQuick
import qs.bar.island
import qs.config
import qs.kit

// The hub's player card: the cover, the track, a thin track with its node,
// previous and the one white play button.
Rectangle {
  id: root

  implicitHeight: 86
  radius: 22
  color: Theme.background1

  function clock(s) { s = Math.max(0, Math.round(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }
  readonly property real progress: IslandService.length > 0 ? Math.min(1, IslandService.position / IslandService.length) : 0

  IslandCover {
    id: cover
    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
    size: 62
    radius: 16
  }

  Column {
    anchors { left: cover.right; leftMargin: 14; right: controls.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
    spacing: 8

    Column {
      width: parent.width
      KitText { width: parent.width; text: IslandService.title || "Nothing playing"; font.pixelSize: 14; font.weight: Font.Medium; elide: Text.ElideRight; textFormat: Text.PlainText }
      KitText { width: parent.width; text: IslandService.artist; color: Theme.muted; font.pixelSize: 12; elide: Text.ElideRight; textFormat: Text.PlainText }
    }

    Row {
      width: parent.width
      spacing: 10
      KitText { text: root.clock(IslandService.position); color: Theme.muted; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
      Item {
        id: bar
        width: parent.width - 2 * 36 - 20
        height: 10
        anchors.verticalCenter: parent.verticalCenter
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.background3 }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * root.progress; height: 4; radius: 2; color: Theme.foreground1 }
        Rectangle {
          x: parent.width * root.progress - 5
          anchors.verticalCenter: parent.verticalCenter
          width: 10; height: 10; radius: 5
          color: Theme.foreground1
        }
        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: mouse => IslandService.seek(mouse.x / width)
        }
      }
      KitText { text: root.clock(IslandService.length); color: Theme.muted; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
    }
  }

  Row {
    id: controls
    anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
    spacing: 6

    IslandButton { anchors.verticalCenter: parent.verticalCenter; icon: "skip-back"; iconSize: 14; onClicked: IslandService.prev() }
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: 46; height: 46; radius: 23
      color: Theme.foreground1
      KitIcon { anchors.centerIn: parent; name: IslandService.playing ? "pause" : "play"; size: 16; solid: true; tint: Theme.background0 }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: IslandService.togglePlay() }
    }
  }
}
