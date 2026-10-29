import QtQuick
import Quickshell.Services.Mpris
import qs.modules.mpd
import qs.modules.yandex

// One player as the shell shows it: what a source of PlayerService (`{key, name, mpd,
// mpris, playing}`, or null) plays, and the controls that go to it. The service
// makes one per family — the music of MPD, the media of other apps — and one for
// whatever the keys control; a null source is "nothing playing".
QtObject {
  id: root

  property var source: null

  readonly property bool mpd: source?.mpd ?? false
  readonly property var mpris: source?.mpris ?? null

  readonly property bool hasMedia: source !== null
  readonly property bool playing: source?.playing ?? false
  readonly property string name: source?.name ?? ""
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

  function togglePlay() {
    if (mpd) MpdService.toggle();
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
}
