import QtQuick
import qs.config
import qs.kit
import qs.bar
import qs.modules.mpd
import qs.modules.yandex

// Yandex Music as a player: the queue, the liked tracks, a search and the
// playlists, with the playing track in its own box at the bottom, or the full
// mode (the player fills the window). The bar module's popup shows the same
// player (YandexNowPlaying, YandexQueue); its options are the same ModuleSettings
// "yandex". Likes and the update are YandexService's, the data YandexLibrary's.
KitFrame {
  id: root

  // the window hides after a track plays (the setting)
  signal closeRequested()

  // a track's ⋮ menu: the window shows it, floating at the button (the anchor)
  signal menuRequested(var track, int index, var anchor)

  property string tab: "likes"
  property bool full: false             // the player fills the window
  property bool confirmDelete: false
  readonly property bool installed: BarLayout.installed("yandex")
  readonly property int downloaded: Object.keys(YandexService.localIds).length

  // the liked tracks the library still lists (an unlike hides a row at once)
  readonly property var shownLikes: YandexLibrary.likes.filter(t => YandexService.liked.includes(t.id))

  // what plays, above the player: the likes say so, with the place in them
  readonly property string playingLabel: MpdService.stopped ? "NOTHING PLAYING"
    : MpdService.source === "likes" ? "PLAYING FROM LIKES · " + MpdService.player.pos + " OF " + MpdService.player.length
    : "PLAYING " + MpdService.source.toUpperCase()

  // the window opens on its default tab, fresh
  function show() {
    if (!installed) return;
    tab = ModuleSettings.get("yandex", "defaultTab", "likes");
    confirmDelete = false;
    YandexLibrary.refreshLikes();
    YandexService.refreshLikes();
    YandexLibrary.refreshPlaylists();
  }

  function choose(value) {
    tab = value;
    confirmDelete = false;
    if (value === "likes") YandexLibrary.refreshLikes();
    if (value === "playlists") YandexLibrary.refreshPlaylists();
  }

  function playTrack(track) {
    YandexLibrary.play(track.id);
    if (ModuleSettings.get("yandex", "closeOnPlay", false)) root.closeRequested();
  }

  // ---- header ----
  KitHeader {
    icon: "music"
    title: "Yandex Music"
    subtitle: root.installed ? YandexService.liked.length + " LIKED · " + root.downloaded + " DOWNLOADED" : "NOT INSTALLED"

    KitButton {
      visible: root.installed
      icon: "layout"
      selected: root.full
      iconTint: root.full ? Theme.foreground0 : Theme.gray
      onClicked: root.full = !root.full
    }

    KitButton {
      visible: root.installed
      icon: "refresh"
      text: "Update"
      busy: YandexService.updating
      disabled: YandexService.updating
      onClicked: YandexService.runUpdate()
    }
  }

  KitChoices {
    visible: root.installed && !root.full
    width: parent.width
    stretch: true
    model: [
      { label: "Queue", value: "queue", icon: "list" },
      { label: "Likes", value: "likes", icon: "heart" },
      { label: "Search", value: "search", icon: "search" },
      { label: "Playlists", value: "playlists", icon: "folder" }
    ]
    current: root.tab
    onPicked: value => root.choose(value)
  }

  KitLine {
    visible: root.installed && !root.full
  }

  KitText {
    visible: !root.installed
    width: parent.width
    text: "Not installed. Add the yandex-music component to use it."
    color: Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  // an error in red, else what the last action did
  KitText {
    visible: root.installed && text !== ""
    width: parent.width
    text: YandexLibrary.error || MpdService.error || YandexLibrary.notice
    color: YandexLibrary.error || MpdService.error ? Theme.red : Theme.muted
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  // the tab's content: the rest of the window above the player box; each tab is a column in it
  Item {
    id: body

    width: parent.width
    visible: root.installed && !root.full
    height: Math.max(0, root.height - 2 * root.padding + root.headerInset - y - bottomPlayer.height - Theme.gapWide)

    // ---- queue ----
    YandexQueue {
      width: parent.width
      visible: root.tab === "queue"
    }

    // ---- likes ----
    Column {
      width: parent.width
      visible: root.tab === "likes"
      spacing: Theme.gapSmall

      KitText {
        visible: root.shownLikes.length === 0
        width: parent.width
        text: YandexLibrary.likesLoading ? "Loading…" : "No liked tracks."
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }

      YandexTrackList {
        id: likesList
        tracks: root.shownLikes
        room: body.height - likesList.y
        onActivated: track => root.playTrack(track)
        onMenu: (track, index, anchor) => root.menuRequested(track, index, anchor)
      }
    }

    // ---- search ----
    Column {
      width: parent.width
      visible: root.tab === "search"
      spacing: Theme.gapSmall

      KitInput {
        placeholder: "search tracks, Enter"
        text: YandexLibrary.query
        onAccepted: YandexLibrary.search(text)
      }

      KitText {
        visible: text !== ""
        width: parent.width
        text: YandexLibrary.searching ? "Searching…"
            : YandexLibrary.results.length === 0 && YandexLibrary.query !== "" ? "Nothing found for \"" + YandexLibrary.query + "\"." : ""
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }

      YandexTrackList {
        id: searchList
        tracks: YandexLibrary.results
        room: body.height - searchList.y
        onActivated: track => root.playTrack(track)
        onMenu: (track, index, anchor) => root.menuRequested(track, index, anchor)
      }
    }

    // ---- playlists: one list; an open playlist shows its tracks under its row ----
    Column {
      width: parent.width
      visible: root.tab === "playlists"
      spacing: Theme.gapSmall

      KitInput {
        id: newPlaylist
        placeholder: "new playlist, Enter"
        onAccepted: {
          YandexLibrary.createPlaylist(text);
          newPlaylist.text = "";
        }
      }

      Flickable {
        id: playlistRows
        width: parent.width
        height: Math.min(contentHeight, body.height - y)
        contentHeight: rowsColumn.implicitHeight
        interactive: contentHeight > height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: rowsColumn
          width: parent.width
          spacing: Theme.gapHair

          KitText {
            visible: YandexLibrary.playlists.length === 0
            width: parent.width
            text: YandexLibrary.playlistsLoading ? "Loading…" : "No playlists yet."
            color: Theme.muted
            font.pixelSize: Theme.fontSize - 1
          }

          Repeater {
            model: YandexLibrary.playlists

            Column {
              id: group

              required property var modelData

              readonly property bool open: YandexLibrary.playlist !== null && YandexLibrary.playlist.kind === modelData.kind

              width: rowsColumn.width
              spacing: Theme.gapHair

              YandexRow {
                label: group.modelData.title
                note: group.modelData.count + (group.modelData.count === 1 ? " track" : " tracks")
                onActivated: {
                  root.confirmDelete = false;
                  if (group.open) YandexLibrary.closePlaylist();
                  else YandexLibrary.openPlaylist(group.modelData);
                }
              }

              Repeater {
                model: group.open ? YandexLibrary.playlist.tracks : []

                YandexTrack {
                  required property var modelData
                  required property int index

                  track: modelData
                  index: index
                  onActivated: root.playTrack(modelData)
                  onMenuRequested: anchor => root.menuRequested(modelData, index, anchor)
                }
              }

              KitText {
                visible: group.open && YandexLibrary.playlist.tracks.length === 0
                width: parent.width
                text: YandexLibrary.playlistLoading ? "Loading…" : "No tracks yet. Add some from a track's ⋮ menu."
                color: Theme.muted
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSize - 1
              }

              YandexRow {
                visible: group.open
                label: root.confirmDelete ? "Sure? Delete " + group.modelData.title : "Delete playlist"
                danger: true
                onActivated: {
                  if (!root.confirmDelete) {
                    root.confirmDelete = true;
                    return;
                  }
                  root.confirmDelete = false;
                  YandexLibrary.deletePlaylist(group.modelData);
                }
              }
            }
          }
        }
      }
    }
  }

  // the playing track, in its own box at the bottom: apart from the list above
  Rectangle {
    id: bottomPlayer

    width: parent.width
    visible: root.installed && !root.full
    height: boxColumn.implicitHeight + 2 * Theme.gapWide
    radius: Theme.radiusCard
    color: Theme.background1

    Column {
      id: boxColumn
      anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.gapWide }
      spacing: Theme.gapSmall

      Item {
        width: parent.width
        height: Theme.fontSize + 10

        KitLabel {
          anchors.verticalCenter: parent.verticalCenter
          text: root.playingLabel
        }

      }

      YandexNowPlaying {
        visible: !MpdService.stopped
        coverSize: 64
      }

      KitButton {
        visible: MpdService.stopped
        icon: "play"
        text: "Play likes"
        onClicked: YandexService.setActive(true)
      }
    }
  }

  // the full mode: the player fills the window, its queue under it
  Column {
    id: fullView

    width: parent.width
    visible: root.installed && root.full
    spacing: Theme.gapWide

    YandexNowPlaying {
      visible: !MpdService.stopped
      coverSize: 168
      side: true
    }

    KitText {
      visible: MpdService.stopped
      width: parent.width
      text: "Nothing playing. Play the likes from the bar or below."
      color: Theme.muted
      wrapMode: Text.WordWrap
      font.pixelSize: Theme.fontSize - 1
    }

    KitButton {
      visible: MpdService.stopped
      icon: "play"
      text: "Play likes"
      onClicked: YandexService.setActive(true)
    }

    KitLabel { text: root.playingLabel }

    YandexQueue {
      id: fullQueue
      width: parent.width
      room: root.height - 2 * root.padding + root.headerInset - fullQueue.y - Theme.gapWide
    }
  }
}
