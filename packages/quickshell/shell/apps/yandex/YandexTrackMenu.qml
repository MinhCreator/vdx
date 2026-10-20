import QtQuick
import qs.config
import qs.kit
import qs.modules.yandex

// The menu of a track, as in a file manager: opened at its ⋮ button, closed by a
// click anywhere else. Play, like, add to a playlist and, inside a playlist,
// take the track out. `host` is the item the menu floats in (the window).
Item {
  id: root

  property Item host: null
  property var track: null
  property int index: -1
  property var inPlaylist: null     // the open playlist {kind, title}, or null
  property bool open: false

  readonly property int menuWidth: 248
  readonly property bool playable: !!track && YandexLibrary.playable(track.id)
  readonly property bool liked: !!track && YandexService.liked.includes(track.id)

  signal played()

  anchors.fill: parent
  visible: open

  // opened at `anchor` (the ⋮ button): under it, or above when there is no room
  function show(trackItem, rowIndex, playlist, anchor) {
    track = trackItem;
    index = rowIndex;
    inPlaylist = playlist;
    const at = anchor.mapToItem(host, 0, 0);
    const x = Math.max(8, Math.min(at.x + anchor.width - menuWidth, host.width - menuWidth - 8));
    const below = at.y + anchor.height + 4;
    const y = below + panel.height > host.height - 8 ? Math.max(8, at.y - panel.height - 4) : below;
    panel.x = x;
    panel.y = y;
    open = true;
  }

  function close() { open = false; }

  // a click outside the panel closes it
  MouseArea {
    anchors.fill: parent
    onClicked: root.close()
  }

  Rectangle {
    id: panel

    width: root.menuWidth
    height: list.implicitHeight + 2 * Theme.gapTight
    radius: Theme.radiusCard
    color: Theme.background1
    border.width: Theme.frameWidth
    border.color: Theme.gray

    Column {
      id: list
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gapTight }
      spacing: Theme.gapHair

      KitText {
        x: Theme.gapMedium
        width: parent.width - 2 * Theme.gapMedium
        text: root.track ? root.track.title : ""
        elide: Text.ElideRight
        font.weight: Font.ExtraBold
      }

      KitLine {}

      YandexRow {
        label: root.playable ? "Play" : "Not downloaded yet"
        disabled: !root.playable
        onActivated: {
          YandexLibrary.play(root.track.id);
          root.close();
          root.played();
        }
      }

      YandexRow {
        label: root.liked ? "Remove from likes" : "Add to likes"
        onActivated: {
          YandexService.toggleLike(root.track.id);
          root.close();
        }
      }

      KitLine {}

      YandexRow {
        visible: YandexLibrary.playlists.length === 0
        label: "No playlists yet"
        disabled: true
      }

      Repeater {
        model: YandexLibrary.playlists

        YandexRow {
          required property var modelData

          label: "Add to " + modelData.title
          note: modelData.count
          onActivated: {
            YandexLibrary.addToPlaylist(modelData, root.track);
            root.close();
          }
        }
      }

      KitLine {
        visible: root.inPlaylist !== null
      }

      YandexRow {
        visible: root.inPlaylist !== null
        label: root.inPlaylist ? "Remove from " + root.inPlaylist.title : ""
        danger: true
        onActivated: {
          YandexLibrary.removeFromPlaylist(root.index);
          root.close();
        }
      }
    }
  }
}
