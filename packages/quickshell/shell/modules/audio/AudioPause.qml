import QtQuick
import Quickshell.Services.Mpris
import qs.config
import qs.modules.mpd

// Smart pause: the music (MPD) pauses while another app plays sound — a video
// in the browser, say — and resumes when that sound stops, if this paused it.
// "Playing" is MPRIS: a player (a browser, mpv, …) reports whether it plays,
// which a PipeWire stream does not (a browser's stream runs while idle too).
// Options in Shell Manager › Modules › Audio (ShellSettings pauseMusic, resumeMusic). Runs
// from shell.qml, so it works whether or not the Audio module is on the bar.
QtObject {
  id: root

  readonly property bool pauseOn: ShellSettings.pauseMusic
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
