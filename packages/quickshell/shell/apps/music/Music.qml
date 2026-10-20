import QtQuick
import qs.bar
import qs.config
import qs.kit
import qs.modules.mpd
import qs.modules.player
import qs.modules.radio
import qs.modules.yandex

// The music player, laid out as Files: the sidebar is a pane of its own (the window's
// header, then LISTEN, YANDEX MUSIC with its playlists, RADIO); the page has its header,
// a field where the page searches or filters, its list as a table in one raised box,
// and the player at its foot (MusicPlayerBar; Now playing shows the player large
// instead). Playback is PlayerService's: MPD (Yandex likes, radio) or any MPRIS player.
// The Yandex and radio sections show only while their components are installed.
Item {
  id: root

  signal closeRequested()

  readonly property int padding: Theme.windowPadding
  readonly property int sideW: 210
  readonly property bool yandexOn: BarLayout.installed("yandex")
  readonly property bool radioOn: BarLayout.installed("radio")

  property string page: "playing"      // playing | likes | search | playlist | radio
  property string playlistKind: ""
  property string filter: ""           // likes and a playlist: the rows that match
  property bool deleteSure: false      // Delete playlist waits for its second press

  readonly property var playlistShown: yandexOn ? YandexLibrary.playlists.find(p => p.kind === playlistKind) ?? null : null
  readonly property bool listPage: page === "likes" || page === "search" || page === "playlist"
  readonly property int downloaded: yandexOn ? Object.keys(YandexService.localIds).length : 0

  // the liked tracks the library still lists (an unlike hides a row at once)
  readonly property var likes: yandexOn ? YandexLibrary.likes.filter(t => YandexService.liked.includes(t.id)) : []
  readonly property var tracks: !yandexOn ? []
    : matching(page === "likes" ? likes
             : page === "search" ? YandexLibrary.results
             : page === "playlist" && YandexLibrary.playlist ? YandexLibrary.playlist.tracks : [])

  function matching(list) {
    const q = page === "search" ? "" : filter.trim().toLowerCase();
    return q === "" ? list : list.filter(t => (t.title + " " + t.artist + " " + t.album).toLowerCase().includes(q));
  }

  // ---- opening ----
  function shown() {
    if (yandexOn) {
      YandexService.setWindowOpen(true);
      YandexService.refreshLikes();
      YandexLibrary.refreshLikes();
      YandexLibrary.refreshPlaylists();
    }
    if (radioOn) RadioService.popupShown();
    const opens = ModuleSettings.get("music", "opensOn", "playing");
    if (opens !== "last") go(opens);
    else if (!available(page)) go("playing");
  }

  function hidden() {
    if (yandexOn) YandexService.setWindowOpen(false);
    menu.close();
  }

  function available(name) {
    if (name === "likes" || name === "search" || name === "playlist") return yandexOn;
    if (name === "radio") return radioOn;
    return name === "playing";
  }

  function go(name) {
    if (!available(name)) name = "playing";
    page = name;
    filter = "";
    deleteSure = false;
    menu.close();
    if (name === "likes") YandexLibrary.refreshLikes();
    if (name === "search") Qt.callLater(() => field.input.forceActiveFocus());
  }

  function openPlaylist(p) {
    go("playlist");
    playlistKind = p.kind;
    YandexLibrary.openPlaylist(p);
  }

  // Escape: the menu, then the filter, then the window
  function cancel() {
    if (menu.open) menu.close();
    else if (filter !== "" && page !== "search") filter = "";
    else closeRequested();
  }

  function played() {
    if (ModuleSettings.get("music", "closeOnPlay", false)) closeRequested();
  }

  function playTrack(track) {
    YandexLibrary.play(track.id);
    played();
  }

  // ---- menus ----
  function trackMenu(track, index, anchor) {
    const playable = YandexLibrary.playable(track.id);
    const liked = YandexService.liked.includes(track.id);
    let items = [
      { label: playable ? "Play" : "Not downloaded yet", disabled: !playable, run: () => root.playTrack(track) },
      { label: liked ? "Remove from likes" : "Add to likes", run: () => YandexService.toggleLike(track.id) },
      { line: true },
    ];
    items = items.concat(YandexLibrary.playlists.length === 0
      ? [{ label: "No playlists yet", disabled: true, run: () => {} }]
      : YandexLibrary.playlists.map(p => ({ label: "Add to " + p.title, note: p.count + "", run: () => YandexLibrary.addToPlaylist(p, track) })));
    if (page === "playlist" && YandexLibrary.playlist)
      items = items.concat([{ line: true },
        { label: "Remove from " + YandexLibrary.playlist.title, danger: true, run: () => YandexLibrary.removeFromPlaylist(index) }]);
    menu.show(track.title, items, anchor);
  }

  function queueMenu(entry, index, anchor) {
    menu.show(entry.title, [
      { label: "Play", run: () => MpdService.play(entry.pos) },
      { label: "Remove from the queue", danger: true, run: () => MpdService.control(["--queue-del", String(entry.pos)]) },
    ], anchor);
  }

  // ---- the sidebar: its own pane, as in Files: the window's header, the sections ----
  Rectangle {
    id: sidePane
    width: root.sideW + root.padding
    height: parent.height
    color: Theme.background0

    Column {
      id: brand
      anchors { left: parent.left; leftMargin: root.padding; right: parent.right; top: parent.top; topMargin: root.padding - Theme.headerInset }
      spacing: Theme.gapGroup

      KitHeader {
        icon: "music"
        title: "Music"
        subtitle: !PlayerService.hasMedia ? "NOTHING PLAYING" : PlayerService.playing ? "PLAYING" : "PAUSED"
      }

      KitLine {}
    }

    MusicSidebar {
      music: root
      yandexOn: root.yandexOn
      radioOn: root.radioOn
      x: root.padding
      y: brand.y + brand.height + Theme.gapGroup
      width: root.sideW - root.padding
      height: parent.height - root.padding - y
    }
  }

  // the line between the panes
  Rectangle {
    anchors { left: sidePane.right; top: parent.top; bottom: parent.bottom }
    width: 1
    color: Theme.background3
  }

  // ---- the page: its header, the field, the list (or the player large), the player ----
  Item {
    id: pageArea
    anchors { left: sidePane.right; right: parent.right; top: parent.top; bottom: parent.bottom
              leftMargin: 1 + root.padding; rightMargin: root.padding }

    KitHeader {
      id: header
      anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: root.padding - Theme.headerInset }
      icon: ({ playing: "play", likes: "heart", search: "search", playlist: "list", radio: "radio" })[root.page]
      title: root.page === "playing" ? "Now playing"
           : root.page === "likes" ? "Likes"
           : root.page === "search" ? "Search"
           : root.page === "radio" ? "Radio"
           : root.playlistShown?.title ?? YandexLibrary.playlist?.title ?? "Playlist"
      subtitle: root.page === "playing" ? (!PlayerService.hasMedia ? "NOTHING RUNNING"
                  : PlayerService.name.toUpperCase() + " · " + (PlayerService.playing ? "PLAYING" : "PAUSED"))
              : root.page === "likes" ? root.likes.length + " LIKED · " + root.downloaded + " DOWNLOADED"
              : root.page === "search" ? (YandexLibrary.query === "" ? "YANDEX MUSIC" : YandexLibrary.results.length + " FOUND")
              : root.page === "radio" ? RadioService.stations.length + " STATIONS"
              : (YandexLibrary.playlist?.tracks.length ?? 0) + " TRACKS"

      KitButton {
        visible: root.yandexOn && root.listPage
        icon: "refresh"
        text: "Update"
        busy: root.yandexOn && YandexService.updating
        disabled: root.yandexOn && YandexService.updating
        onClicked: YandexService.runUpdate()
      }

      KitButton {
        visible: root.page === "playlist"
        icon: "trash"
        text: root.deleteSure ? "Sure?" : "Delete"
        onClicked: {
          if (!root.deleteSure) { root.deleteSure = true; sureTimer.restart(); return; }
          root.deleteSure = false;
          if (root.playlistShown) YandexLibrary.deletePlaylist(root.playlistShown);
          root.go("likes");
        }
      }
    }

    Timer { id: sureTimer; interval: 3000; onTriggered: root.deleteSure = false }

    KitLine {
      id: headerLine
      anchors { top: header.bottom; topMargin: Theme.gapGroup }
      width: parent.width
    }

    // ---- the field: Search asks Yandex on Enter, Likes and a playlist filter as you type ----
    KitInput {
      id: field
      visible: root.listPage
      anchors { top: headerLine.bottom; topMargin: Theme.gapGroup }
      width: parent.width
      placeholder: root.page === "search" ? "artist, track or album, Enter" : "filter"
      text: root.page === "search" ? YandexLibrary.query : root.filter
      onTextEdited: if (root.page !== "search") root.filter = text
      onAccepted: if (root.page === "search") YandexLibrary.search(text)
    }

    // an error in red, else what the last action did
    KitText {
      id: note
      readonly property string err: root.yandexOn ? (YandexLibrary.error || MpdService.error) : MpdService.error
      visible: text !== "" && root.page !== "playing"
      anchors { top: field.visible ? field.bottom : headerLine.bottom; topMargin: Theme.gapMedium }
      width: parent.width
      text: err || (root.yandexOn ? YandexLibrary.notice : "")
      color: err ? Theme.red : Theme.muted
      wrapMode: Text.WordWrap
      font.pixelSize: Theme.fontSize - 1
    }

    // ---- body ----
    Item {
      id: body
      anchors { left: parent.left; right: parent.right; bottom: bar.visible ? bar.top : parent.bottom
                top: note.visible ? note.bottom : field.visible ? field.bottom : headerLine.bottom
                topMargin: Theme.gapGroup; bottomMargin: bar.visible ? Theme.gapGroup : root.padding }

      MusicNowPlaying {
        anchors.fill: parent
        visible: root.page === "playing"
        yandexOn: root.yandexOn
        radioOn: root.radioOn
        onGoTo: name => root.go(name)
        onQueueMenu: (entry, index, anchor) => root.queueMenu(entry, index, anchor)
      }

      MusicTracks {
        anchors.fill: parent
        visible: root.listPage
        kind: "yandex"
        tracks: root.tracks
        empty: !root.yandexOn ? "" : root.page === "likes" ? (YandexLibrary.likesLoading ? "Loading…" : root.filter !== "" ? "Nothing matches" : "No liked tracks")
             : root.page === "search" ? (YandexLibrary.searching ? "Searching…"
                 : YandexLibrary.query === "" ? "Type and press Enter to search Yandex Music"
                 : "Nothing found for “" + YandexLibrary.query + "”")
             : YandexLibrary.playlistLoading ? "Loading…" : root.filter !== "" ? "Nothing matches"
             : "No tracks yet. Add some from a track's ⋮ menu"
        onActivated: track => root.playTrack(track)
        onMenu: (track, index, anchor) => root.trackMenu(track, index, anchor)
      }

      MusicTracks {
        anchors.fill: parent
        visible: root.page === "radio"
        kind: "radio"
        tracks: root.radioOn ? RadioService.stations : []
        empty: "No stations. Add them with the radio command"
        onActivated: station => { RadioService.play(station.key); root.played(); }
      }
    }

    MusicPlayerBar {
      id: bar
      visible: root.page !== "playing" && PlayerService.hasMedia
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom; bottomMargin: root.padding }
      yandexOn: root.yandexOn
      onOpened: root.go("playing")
    }
  }

  // above the window's content: a click outside it closes it
  MusicMenu {
    id: menu
    host: root
  }
}
