import QtQuick
import Quickshell.Services.Mpris
import qs.config
import qs.modules.mpd

// One source at a time (Sound › One source at a time): the music and the radio (both MPD, one
// queue: a station parks the music, see music.sh) and an app's media (MPRIS) do not play together.
// Each side's start is read from what it plays, not from who asked: MPD starting a track or a
// station (from the shell, ncmpcpp or mpc alike) pauses the apps' players; an app starting pauses MPD.
//
// Smart pause: the music (MPD) pauses while another app plays sound — a video
// in the browser, say — and resumes when that sound stops, if this paused it.
// "Playing" is MPRIS: a player (a browser, mpv, …) reports whether it plays,
// which a PipeWire stream does not (a browser's stream runs while idle too).
// Options in Shell Manager › Sound (ShellSettings exclusiveSound, pauseMusic, resumeMusic). Runs
// from shell.qml, so it works whether or not the Audio module is on the bar.
QtObject {
  id: root

  readonly property bool exclusive: ShellSettings.exclusiveSound
  readonly property bool pauseOn: ShellSettings.pauseMusic || exclusive
  readonly property bool resumeOn: ShellSettings.resumeMusic

  // ---- MPD starts something: the apps' media pauses ----
  // what MPD plays ("" when it does not): a new value is a start — a track, the music coming
  // back, a station, even one replacing the music (MPD "playing" all the way through)
  readonly property string mpdTrack: MpdService.playing ? MpdService.file : ""
  // the first state read after the shell starts (MPD up or down) is not a start
  property bool known: false
  readonly property bool mpdRead: MpdService.player.service !== undefined
  onMpdReadChanged: if (mpdRead) Qt.callLater(() => root.known = true)
  onMpdTrackChanged: {
    if (mpdTrack === "") return;
    pausedHere = false;                // the music is the user's again
    if (!known || !exclusive) return;
    for (const p of Mpris.players.values)
      if (p.isPlaying && p.canPause) p.pause();
  }

  // ---- an app starts: MPD pauses (and comes back, with Resume) ----
  // some other player is playing (MPD is not an MPRIS player here)
  readonly property bool otherSound: Mpris.players.values.some(p => p.isPlaying)
  property bool pausedHere: false     // the music was paused by this, not by hand
  readonly property bool mpdStopped: MpdService.stopped
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
