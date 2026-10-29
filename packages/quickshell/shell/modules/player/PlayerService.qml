pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import qs.config
import qs.modules.mpd
import qs.modules.radio
import qs.modules.yandex

// The shell's three players, each with its own popup, bar module and live activity:
//   music  MPD playing its own music (the Yandex likes, the local files); while a station has
//          MPD's one queue, the music it put aside, frozen as it stood (MpdService.parkedTrack)
//   radio  MPD playing a station (RadioService)
//   media  the other apps, over MPRIS (a browser, mpv, Spotify)
// `view` is the one the keys, the hub's card and the island control: the one that plays (the
// radio, the music, the media), else a paused one in the same order.
Singleton {
  id: root

  // ---- tuning ----
  readonly property int positionMs: 1000     // an MPRIS position is read, not pushed: asked this often while playing

  // Music › Players: all (every MPRIS player), music (none: MPD only), pick (the ones not in
  // hiddenPlayers, by name).
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

  // ---- the sources: {key, name, playing} and mpd, parked or mpris ----
  readonly property bool mpdMusic: !MpdService.stopped && MpdService.source !== "radio"
  readonly property var musicSource: mpdMusic
    ? { key: "mpd", name: MpdService.source === "files" ? "Files" : "Yandex Music", mpd: true, playing: MpdService.playing }
    : MpdService.parked ? { key: "parked", name: "Paused by the radio", parked: true, playing: false, track: MpdService.parkedTrack }
    : null
  // the music's queue: MPD's, or the one put aside with it; never a station's
  readonly property var musicQueue: musicSource?.parked ? MpdService.parkedQueue : musicSource ? MpdService.queue : []
  readonly property var radioSource: RadioService.active ? { key: "radio", name: "Radio", mpd: true, playing: MpdService.playing } : null
  // the apps' players, by their unique id
  readonly property var externals: {
    const list = [];
    for (const p of Mpris.players.values)
      if (shownPlayer(p)) list.push({ key: p.uniqueId || p.dbusName, name: nameOf(p), mpris: p, playing: p.isPlaying });
    return list;
  }
  property string mediaPicked: ""              // an app's key, chosen in the Media popup
  readonly property var mediaSource: externals.find(s => s.key === mediaPicked)
                                     ?? externals.find(s => s.playing) ?? externals[0] ?? null

  readonly property PlayerView music: PlayerView { source: root.musicSource }
  readonly property PlayerView radioView: PlayerView { source: root.radioSource }
  readonly property PlayerView media: PlayerView { source: root.mediaSource }

  // ---- what the keys control ----
  // radio | music | media | "" (nothing at all)
  readonly property string family: radioView.playing ? "radio" : music.playing ? "music" : media.playing ? "media"
                                 : radioView.hasMedia ? "radio" : music.hasMedia ? "music" : media.hasMedia ? "media" : ""
  readonly property PlayerView view: family === "radio" ? radioView : family === "media" ? media : music

  readonly property bool mpd: view.mpd
  readonly property var mpris: view.mpris
  readonly property bool hasMedia: view.hasMedia
  readonly property bool playing: view.playing
  readonly property string name: view.name
  readonly property bool radio: view.radio
  readonly property string title: view.title
  readonly property string artist: view.artist
  readonly property string cover: view.cover
  readonly property real position: view.position
  readonly property real length: view.length
  readonly property bool canNext: view.canNext
  readonly property bool canPrevious: view.canPrevious
  readonly property bool canSeek: view.canSeek
  readonly property bool canRaise: view.canRaise
  readonly property bool shuffleOn: view.shuffleOn
  readonly property bool canShuffle: view.canShuffle
  readonly property string loop: view.loop
  readonly property bool canLoop: view.canLoop

  // ---- actions: the player the keys control ----
  function togglePlay() {
    if (family === "") YandexService.setActive(true);     // nothing at all: the likes
    else view.togglePlay();
  }
  function next() { view.next(); }
  function prev() { view.prev(); }
  function seek(fraction) { view.seek(fraction); }
  function toggleShuffle() { view.toggleShuffle(); }
  function cycleLoop() { view.cycleLoop(); }
  function raise() { view.raise(); }

  // an MPRIS position is read, not pushed: ask for it while something plays
  Timer {
    running: root.externals.some(s => s.playing)
    interval: root.positionMs
    repeat: true
    onTriggered: { for (const s of root.externals) if (s.playing) s.mpris.positionChanged(); }
  }
}
