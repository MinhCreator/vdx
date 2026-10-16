import QtQuick
import Quickshell.Services.Pipewire
import qs.config
import qs.modules.audio
import qs.modules.mpd

// Smart pause: the music (MPD) pauses while another app plays sound — a video
// in the browser, say — and resumes when that sound stops, if this paused it.
// Options in Shell Manager › Media (ShellSettings pauseMusic, resumeMusic). Runs
// from shell.qml, so it works whether or not the Audio module is on the bar.
QtObject {
  id: root

  readonly property bool pauseOn: ShellSettings.pauseMusic
  readonly property bool resumeOn: ShellSettings.resumeMusic

  // an output stream of another app is running (MPD's own stream does not count)
  readonly property bool otherSound: AudioService.streams.some(n => n.state === PwNodeState.Running && !isMusic(n))

  property bool pausedHere: false     // the music was paused by this, not by hand

  function isMusic(node) {
    const app = node.properties["application.process.binary"] || node.properties["application.name"] || "";
    return app.toLowerCase() === "mpd";
  }

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
