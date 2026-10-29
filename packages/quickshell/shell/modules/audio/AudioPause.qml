import QtQuick
import Quickshell.Services.Mpris
import qs.config
import qs.modules.mpd

// One source at a time (Sound › One source at a time): the music (MPD, a station too) and an app's media
// do not play together — whichever starts last, the other is paused.
//
// Smart pause: the music (MPD) pauses while another app plays sound — a video
// in the browser, say — and resumes when that sound stops, if this paused it.
// "Playing" is MPRIS: a player (a browser, mpv, …) reports whether it plays,
// which a PipeWire stream does not (a browser's stream runs while idle too).
// Options in Shell Manager › Modules › Audio (ShellSettings pauseMusic, resumeMusic). Runs
// from shell.qml, so it works whether or not the Audio module is on the bar.
QtObject {
  id: root

  readonly property bool exclusive: ShellSettings.exclusiveSound
  readonly property bool pauseOn: ShellSettings.pauseMusic || exclusive
  readonly property bool resumeOn: ShellSettings.resumeMusic

  // some other player is playing (MPD is not an MPRIS player here)
  readonly property bool otherSound: Mpris.players.values.some(p => p.isPlaying)

  property bool pausedHere: false     // the music was paused by this, not by hand

  // The music is taken back by hand (played or stopped) while this paused it:
  // from now on it is the user's, and nothing resumes it. Our own pause and
  // resume come through here too, harmlessly: the pause only stops playback,
  // and the resume clears the flag before it plays.
  readonly property bool mpdPlaying: MpdService.playing
  readonly property bool mpdStopped: MpdService.stopped
  onMpdPlayingChanged: if (mpdPlaying) pausedHere = false;

  // the music or a station is being started: the apps' media (a browser, mpv, …) that plays stops
  // (One source at a time); MpdService says so, the state alone misses a station replacing music
  readonly property Connections starts: Connections {
    target: MpdService
    function onStarted() {
      if (!root.exclusive) return;
      root.pausedHere = false;
      for (const p of Mpris.players.values)
        if (p.isPlaying && p.canPause) p.pause();
    }
  }
  onMpdStoppedChanged: pausedHere = false;

  onOtherSoundChanged: {
    if (otherSound) {
      if (pauseOn && MpdService.playing) {
        MpdService.pause();
        pausedHere = true;
      }
    } else if (pausedHere) {
      pausedHere = false;
      if (resumeOn && MpdService.paused) MpdService.play();
    }
  }
}
