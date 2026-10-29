import QtQuick
import qs.components
import qs.config
import qs.modules.mpd
import qs.modules.player
import qs.kit

// MPD's queue, whatever plays it (the likes, the files, a playlist): two lines per
// track, nine rows visible, then it scrolls. It scrolls itself so the current track
// sits on top. A click plays a track, a right click takes it out; the search button
// swaps the list for matches. An MPRIS player has no queue here: a line says so.
Column {
  id: root

  property bool searching: false
  property string query: ""

  readonly property int rowHeight: 38
  readonly property int upNext: 9
  // while a station has the queue the player is frozen: its queue and place are the kept ones
  readonly property bool frozen: PlayerService.musicSource?.parked ?? false
  readonly property int currentPos: frozen ? PlayerService.musicSource.track.pos : (MpdService.player.pos ?? 0)
  readonly property string notice: PlayerService.hasMedia && !PlayerService.mpd ? PlayerService.name + " keeps its own queue" : ""
  readonly property var tracks: {
    const queue = PlayerService.musicQueue;
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

  KitText {
    visible: root.notice !== ""
    width: parent.width
    text: root.notice
    color: Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  Item {
    visible: root.notice === ""
    width: parent.width
    height: searchButton.height

    KitLabel {
      anchors.verticalCenter: parent.verticalCenter
      text: root.searching ? "SEARCH" : "UP NEXT FROM #" + root.currentPos
    }

    // re-read MPD's queue
    KitButton {
      anchors { right: searchButton.left; rightMargin: Theme.gapMedium }
      icon: "refresh"
      onClicked: MpdService.refreshQueue()
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
    visible: root.searching && root.notice === ""
    placeholder: "Search artist or title…"
    text: root.query
    onTextEdited: root.query = text
  }

  Flickable {
    id: list
    visible: root.notice === ""
    width: parent.width
    height: Math.min(contentHeight, root.upNext * root.rowHeight)
    contentHeight: rows.implicitHeight
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: rows
      width: parent.width

      Repeater {
        model: root.tracks

        Rectangle {
          radius: Theme.radiusControl
          id: row

          required property var modelData

          readonly property bool current: modelData.pos === root.currentPos

          width: rows.width
          height: root.rowHeight
          color: current ? Theme.background3 : hover.hovered ? Theme.background1 : Theme.clear
          Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

          HoverHandler { id: hover }

          KitText {
            id: number
            anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
            width: 32
            text: row.modelData.pos
            color: row.current ? Theme.foreground0 : Theme.muted
            Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
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
              Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
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

          // click plays it; right click takes it out of the queue
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
              if (root.frozen) { MpdService.unpark(); return; }       // frozen: a click brings the music back
              if (mouse.button === Qt.RightButton) MpdService.control(["--queue-del", String(row.modelData.pos)]);
              else {
                MpdService.play(row.modelData.pos);
                root.searching = false;
              }
            }
          }
        }
      }
    }
  }

  KitText {
    visible: root.notice === "" && root.tracks.length === 0
    text: root.searching ? (root.query.trim() === "" ? "Type to search." : "Nothing matches") : "The queue is empty."
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
  }
}
