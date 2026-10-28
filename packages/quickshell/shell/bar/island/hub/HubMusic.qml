import QtQuick
import qs.bar.island
import qs.config
import qs.kit

// The hub's player card: the cover, the track and "artist · position / length",
// previous and the one white play button.
Rectangle {
  id: root

  implicitHeight: 80
  radius: 22
  color: Theme.background1

  function clock(s) { s = Math.max(0, Math.round(s)); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0"); }

  IslandCover {
    id: cover
    anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
    size: 54
    radius: 14
  }

  Column {
    anchors { left: cover.right; leftMargin: 14; right: controls.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
    spacing: 2
    KitText { width: parent.width; text: IslandService.title || "Nothing playing"; font.pixelSize: 14; font.weight: Font.Medium; elide: Text.ElideRight; textFormat: Text.PlainText }
    KitText {
      width: parent.width
      text: (IslandService.artist !== "" ? IslandService.artist + " · " : "") + root.clock(IslandService.position) + " / " + root.clock(IslandService.length)
      color: Theme.muted
      font.pixelSize: 12
      elide: Text.ElideRight
      textFormat: Text.PlainText
    }
  }

  Row {
    id: controls
    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
    spacing: 6

    IslandButton { anchors.verticalCenter: parent.verticalCenter; icon: "skip-back"; iconSize: 14; onClicked: IslandService.prev() }
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: 44; height: 44; radius: 22
      color: Theme.foreground1
      KitIcon { anchors.centerIn: parent; name: IslandService.playing ? "pause" : "play"; size: 16; solid: true; tint: Theme.background0 }
      MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: IslandService.togglePlay() }
    }
  }
}
