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

  // an output stream of another app is running (MPD's own stream does not count):
  // PwNode has no state, its links do; a link reports it only while bound
  readonly property var streamLinks: Pipewire.links.values.filter(l => AudioService.streams.includes(l.source))
  readonly property bool otherSound: streamLinks.some(l => l.state === PwLinkState.Active && !isMusic(l.source))

  property PwObjectTracker tracker: PwObjectTracker {
    objects: root.streamLinks
  }

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
