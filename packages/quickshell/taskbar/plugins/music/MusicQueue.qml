import QtQuick
import qs.components
import qs.config
import qs.plugins.mpd

// The whole queue, two lines per track, Theme.musicUpNext rows visible. It
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

  spacing: 6

  PopupSectionTitle {
    width: parent.width
    text: root.searching ? "SEARCH" : "QUEUE"

    PopupButton {
      glyph: root.searching ? Theme.iconError : Theme.iconSearch
      tint: Theme.foreground0
      frameless: true
      hoverBackground: false
      onClicked: {
        root.searching = !root.searching;
        root.query = "";
        if (root.searching) search.input.forceActiveFocus();
      }
    }
  }

  PopupInput {
    id: search
    width: parent.width
    visible: root.searching
    placeholder: "ARTIST OR TITLE"
    text: root.query
    onTextEdited: root.query = text
  }

  Flickable {
    id: list
    width: parent.width
    height: Math.min(contentHeight, Theme.musicUpNext * root.rowHeight)
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
          color: hover.hovered ? Theme.background2 : "transparent"

          HoverHandler { id: hover }

          Rectangle {
            visible: row.current
            width: 2
            height: parent.height
            color: Theme.foreground0
          }

          ThemeText {
            id: number
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            width: 30
            text: row.modelData.pos
            color: Theme.dim
            font.pixelSize: Theme.fontSize - 2
          }

          Column {
            anchors {
              left: number.right; leftMargin: 6
              right: parent.right; rightMargin: 8
              verticalCenter: parent.verticalCenter
            }
            spacing: 1

            ThemeText {
              width: parent.width
              text: row.modelData.title
              elide: Text.ElideRight
              color: row.current || hover.hovered ? Theme.foreground0 : Theme.foreground2
              font.pixelSize: Theme.fontSize - 1
            }

            ThemeText {
              width: parent.width
              text: row.modelData.artist
              elide: Text.ElideRight
              color: Theme.dim
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

  ThemeText {
    visible: root.tracks.length === 0
    text: root.searching ? (root.query.trim() === "" ? "TYPE TO SEARCH" : "NOTHING FOUND") : "QUEUE IS EMPTY"
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }
}
