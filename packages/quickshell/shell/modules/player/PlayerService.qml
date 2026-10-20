pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.config
import qs.modules.mpd
import qs.modules.yandex

// Every media player in one list: MPD (the Yandex likes and the radio, through
// MpdService) and each MPRIS player (Spotify, a browser, mpv). The island and the
// Player module show one of them, and the controls go to it. Which one: the pick
// of the Player popup while it runs, else a playing one (MPD first), else MPD when
// it has something queued, else the first player there is.
Singleton {
  id: root

  // ---- tuning ----
  readonly property int positionMs: 1000     // an MPRIS position is read, not pushed: asked this often while playing

  property string picked: ""                 // a source's key, chosen in the popup

  // {key, name, mpd, mpris, playing}: MPRIS players by their unique id
  readonly property var sources: {
    const list = [];
    if (!MpdService.stopped)
      list.push({ key: "mpd", name: MpdService.source === "radio" ? "Radio" : "Yandex Music", mpd: true, playing: MpdService.playing });
    for (const p of Mpris.players.values)
      list.push({ key: p.uniqueId || p.dbusName, name: p.identity || p.desktopEntry || p.dbusName, mpris: p, playing: p.isPlaying });
    return list;
  }

  readonly property var current: sources.find(s => s.key === picked)
                                 ?? sources.find(s => s.playing)
                                 ?? sources.find(s => s.mpd)
                                 ?? sources[0] ?? null
  readonly property bool mpd: current?.mpd ?? false
  readonly property var mpris: current?.mpris ?? null

  // ---- what the current player shows ----
  readonly property bool hasMedia: current !== null
  readonly property bool playing: current?.playing ?? false
  readonly property string name: current?.name ?? ""
  readonly property bool radio: mpd && MpdService.source === "radio"
  readonly property string title: mpd ? (MpdService.player.title || MpdService.player.station
                                         || MpdService.file.split("/").pop())
                                      : (mpris?.trackTitle ?? "")
  readonly property string artist: mpd ? (radio ? MpdService.player.station : MpdService.player.artist)
                                       : (mpris?.trackArtist ?? "")
  readonly property string cover: mpd ? YandexService.cover : (mpris?.trackArtUrl ?? "")
  readonly property real position: mpd ? MpdService.elapsed : (mpris?.position ?? 0)
  readonly property real length: mpd ? MpdService.duration : (mpris?.length ?? 0)
  readonly property bool canNext: mpd ? true : (mpris?.canGoNext ?? false)
  readonly property bool canPrevious: mpd ? true : (mpris?.canGoPrevious ?? false)
  readonly property bool canSeek: length > 0 && (mpd || (mpris?.canSeek ?? false))
  readonly property bool canRaise: !mpd && (mpris?.canRaise ?? false)
  readonly property bool shuffleOn: mpd ? MpdService.player.random === true : (mpris?.shuffle ?? false)
  readonly property bool canShuffle: mpd || (mpris?.shuffleSupported ?? false)
  readonly property string loop: mpd ? (MpdService.player.repeat ?? "off")
                                     : mpris?.loopState === MprisLoopState.Track ? "one"
                                     : mpris?.loopState === MprisLoopState.Playlist ? "all" : "off"
  readonly property bool canLoop: mpd || (mpris?.loopSupported ?? false)

  // ---- actions: the current player ----
  function togglePlay() {
    if (!current) YandexService.setActive(true);     // nothing running: the likes
    else if (mpd) MpdService.toggle();
    else if (mpris?.canTogglePlaying) mpris.togglePlaying();
  }
  function next() { if (mpd) MpdService.next(); else if (mpris?.canGoNext) mpris.next(); }
  function prev() { if (mpd) MpdService.prev(); else if (mpris?.canGoPrevious) mpris.previous(); }
  function seek(fraction) {
    if (!canSeek) return;
    if (mpd) MpdService.seek(fraction);
    else mpris.position = fraction * length;
  }
  function toggleShuffle() {
    if (mpd) MpdService.toggleRandom();
    else if (mpris?.shuffleSupported) mpris.shuffle = !mpris.shuffle;
  }
  // off -> all -> one -> off for MPD; the MPRIS loop states in their order
  function cycleLoop() {
    if (mpd) MpdService.cycleRepeat();
    else if (mpris?.loopSupported) {
      const s = mpris.loopState;
      mpris.loopState = s === MprisLoopState.None ? MprisLoopState.Playlist
                      : s === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None;
    }
  }
  function raise() { if (canRaise) mpris.raise(); }

  // an MPRIS position is read, not pushed: ask for it while playing
  Timer {
    running: root.hasMedia && !root.mpd && root.playing
    interval: root.positionMs
    repeat: true
    onTriggered: root.mpris?.positionChanged()
  }
}
