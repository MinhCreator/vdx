pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.config
import qs.modules.mpd
import qs.modules.yandex

// Every media player in one list: MPD (the Yandex likes, the local files and the
// radio, through MpdService) and each MPRIS player (Spotify, a browser, mpv). The
// island and the music module show one of them, and the controls go to it. Which one: the pick
// of the Player popup while it runs, else a playing one (MPD first), else MPD when
// it has something queued, else the first player there is.
Singleton {
  id: root

  // ---- tuning ----
  readonly property int positionMs: 1000     // an MPRIS position is read, not pushed: asked this often while playing

  property string picked: ""                 // a source's key, chosen in the popup

  // Music › Players: all (every MPRIS player), music (none: MPD only), pick (the ones not in
  // hiddenPlayers, by name). MPD is always a source.
  readonly property string playersShown: ModuleSettings.get("music", "players", "all")
  readonly property var hiddenPlayers: ModuleSettings.get("music", "hiddenPlayers", [])

  // a player's name as the lists show it (Music › Players lists the same names)
  function nameOf(p) { return p.identity || p.desktopEntry || p.dbusName; }

  // the names of the MPRIS players running now
  readonly property var mprisNames: {
    const names = [];
    for (const p of Mpris.players.values) names.push(nameOf(p));
    return names;
  }

  function shownPlayer(p) {
    if (playersShown === "music") return false;
    if (playersShown === "pick") return !hiddenPlayers.includes(nameOf(p));
    return true;
  }

  // {key, name, mpd, mpris, playing}: MPRIS players by their unique id
  readonly property var sources: {
    const list = [];
    if (!MpdService.stopped)
      list.push({ key: "mpd", name: MpdService.source === "radio" ? "Radio" : MpdService.source === "files" ? "Files" : "Yandex Music",
                  mpd: true, playing: MpdService.playing });
    for (const p of Mpris.players.values)
      if (shownPlayer(p)) list.push({ key: p.uniqueId || p.dbusName, name: nameOf(p), mpris: p, playing: p.isPlaying });
    return list;
  }

  readonly property var current: sources.find(s => s.key === picked)
                                 ?? sources.find(s => s.playing)
                                 ?? sources.find(s => s.mpd)
                                 ?? sources[0] ?? null
  // ---- the families: the music of MPD (no radio), the radio, the media of other apps ----
  // Each shows apart (a live activity, a popup); `current` is only what the keys control.
  // What MPD's music was, kept while a station has the queue: the player is frozen as it stood
  // (track, cover, place, queue). Updated while the music is MPD's own; after a restart of the
  // shell only what the script noted (title, artist, place) is left.
  property var frozen: null
  readonly property var musicNow: MpdService.source !== "radio" && !MpdService.stopped ? {
    title: MpdService.player.title || MpdService.file.split("/").pop(), artist: MpdService.player.artist ?? "",
    album: MpdService.player.album ?? "", year: MpdService.player.year ?? "",
    cover: YandexService.cover, position: MpdService.elapsed, length: MpdService.duration, pos: MpdService.player.pos ?? 0,
    name: MpdService.source === "files" ? "Files" : "Yandex Music", queue: MpdService.queue } : null
  onMusicNowChanged: {
    if (!musicNow) return;
    // a queue cleared for the station must not wipe the one kept
    frozen = Object.assign({}, musicNow, { queue: musicNow.queue.length > 0 ? musicNow.queue : (frozen?.queue ?? []) });
  }
  readonly property var parkedTrack: {
    const t = MpdService.parkedTrack;
    if (!t) return null;
    return frozen ?? { title: t.title, artist: t.artist, album: "", year: "", cover: "", position: t.elapsed, length: t.duration, pos: t.pos, queue: [] };
  }
  // (read from MPD directly, not through `music`: that one reads this)
  // the music is MPD's, or — while a station has the queue — the frozen player, paused
  readonly property var musicSource: sources.find(s => s.mpd && MpdService.source !== "radio")
    ?? (parkedTrack ? { key: "parked", name: "Paused by the radio", parked: true, playing: false, track: parkedTrack } : null)
  // its queue: MPD's, or the frozen one
  readonly property var musicQueue: musicSource?.parked ? musicSource.track.queue : MpdService.queue
  readonly property var externals: sources.filter(s => s.mpris)
  property string mediaPicked: ""              // an app's key, chosen in the Media popup
  readonly property var mediaSource: externals.find(s => s.key === mediaPicked)
                                     ?? externals.find(s => s.playing) ?? externals[0] ?? null
  readonly property PlayerView music: PlayerView { source: root.musicSource }
  readonly property PlayerView media: PlayerView { source: root.mediaSource }
  readonly property PlayerView view: PlayerView { id: cur; source: root.current }

  // ---- what the keys control (the current player) ----
  property alias mpd: cur.mpd
  property alias mpris: cur.mpris
  property alias hasMedia: cur.hasMedia
  property alias playing: cur.playing
  property alias name: cur.name
  property alias radio: cur.radio
  property alias title: cur.title
  property alias artist: cur.artist
  property alias cover: cur.cover
  property alias position: cur.position
  property alias length: cur.length
  property alias canNext: cur.canNext
  property alias canPrevious: cur.canPrevious
  property alias canSeek: cur.canSeek
  property alias canRaise: cur.canRaise
  property alias shuffleOn: cur.shuffleOn
  property alias canShuffle: cur.canShuffle
  property alias loop: cur.loop
  property alias canLoop: cur.canLoop

  // ---- actions: the current player ----
  function togglePlay() {
    if (!current) YandexService.setActive(true);     // nothing running: the likes
    else cur.togglePlay();
  }
  function next() { cur.next(); }
  function prev() { cur.prev(); }
  function seek(fraction) { cur.seek(fraction); }
  function toggleShuffle() { cur.toggleShuffle(); }
  function cycleLoop() { cur.cycleLoop(); }
  function raise() { cur.raise(); }

  // an MPRIS position is read, not pushed: ask for it while something plays
  Timer {
    running: root.sources.some(s => s.mpris && s.playing)
    interval: root.positionMs
    repeat: true
    onTriggered: { for (const s of root.externals) if (s.playing) s.mpris.positionChanged(); }
  }
}
