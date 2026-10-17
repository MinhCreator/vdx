import QtQuick
import qs.components
import qs.config
import qs.modules.mpd
import qs.kit

// The whole queue, two lines per track, MusicService.upNext rows visible. It
// scrolls itself so the current track sits on top (earlier tracks above,
// upcoming below). The search button swaps it for matches across the queue.
Column {
  id: root

  property bool searching: false
  property string query: ""

  readonly property int rowHeight: 38
  readonly property int currentPos: MpdService.player.pos ?? 0
  readonly property var tracks: {
    const queue = MusicService.queue;
    if (!searching) return queue;
    const q = query.trim().toLowerCase();
    return q === "" ? [] : queue.filter(t => (t.artist + " " + t.title).toLowerCase().includes(q));
  }

  function scrollToCurrent() {
    if (searching || list.moving) return;
    const index = tracks.findIndex(t => t.pos === currentPos);
    list.contentY = Math.max(0, Math.min(index * rowHeight, list.contentHeight - list.height));
  }

  onTracksChanged: Qt.callLater(scrollToCurrent)
  onCurrentPosChanged: Qt.callLater(scrollToCurrent)
  onSearchingChanged: if (!searching) Qt.callLater(scrollToCurrent)

  spacing: Theme.gapMedium

  Item {
    width: parent.width
    height: searchButton.height

    KitLabel {
      anchors.verticalCenter: parent.verticalCenter
      text: root.searching ? "SEARCH" : "UP NEXT FROM #" + root.currentPos
    }

    // re-fetch the likes from Yandex Music
    KitButton {
      anchors { right: searchButton.left; rightMargin: Theme.gapMedium }
      icon: "refresh"
      busy: MusicService.updating
      onClicked: MusicService.runUpdate()
    }

    KitButton {
      id: searchButton
      anchors.right: parent.right
      icon: root.searching ? "x" : "search"
      onClicked: {
        root.searching = !root.searching;
        root.query = "";
        if (root.searching) search.input.forceActiveFocus();
      }
    }
  }

  KitInput {
    id: search
    visible: root.searching
    placeholder: "artist or title"
    text: root.query
    onTextEdited: root.query = text
  }

  Flickable {
    id: list
    width: parent.width
    height: Math.min(contentHeight, MusicService.upNext * root.rowHeight)
    contentHeight: rows.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: rows
      width: parent.width

      Repeater {
        model: root.tracks

        Rectangle {
          id: row

          required property var modelData

          readonly property bool current: modelData.pos === root.currentPos

          width: rows.width
          height: root.rowHeight
          color: current ? Theme.background3 : hover.hovered ? Theme.background1 : "transparent"

          HoverHandler { id: hover }

          KitText {
            id: number
            anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
            width: 32
            text: row.modelData.pos
            color: row.current ? Theme.foreground0 : Theme.gray
            font.pixelSize: Theme.fontSize - 2
          }

          Column {
            anchors {
              left: number.right; leftMargin: 4
              right: parent.right; rightMargin: Theme.gapLoose
              verticalCenter: parent.verticalCenter
            }
            spacing: 1

            KitText {
              width: parent.width
              text: row.modelData.title
              elide: Text.ElideRight
              color: row.current || hover.hovered ? Theme.foreground0 : Theme.foreground2
              font.weight: row.current ? Font.ExtraBold : Font.DemiBold
              font.pixelSize: Theme.fontSize - 1
            }

            KitText {
              width: parent.width
              text: row.modelData.artist
              elide: Text.ElideRight
              color: Theme.muted
              font.pixelSize: Theme.fontSize - 2
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              MpdService.play(row.modelData.pos);
              root.searching = false;
            }
          }
        }
      }
    }
  }

  KitText {
    visible: root.tracks.length === 0
    text: root.searching ? (root.query.trim() === "" ? "Type to search." : "Nothing found.") : "The queue is empty."
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
  }
}
