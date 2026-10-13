pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.plugins.mpd

// Internet radio on top of MpdService: stations from radio-cli's
// stations.json. The bar module and the popup read MpdService for playback and
// this service for the stations.
Singleton {
  id: root

  readonly property bool active: MpdService.source === "radio" && !MpdService.stopped

  property var stations: []                    // [{key, name}]
  readonly property string stationKey: stations.find(s => s.name === MpdService.player.station)?.key ?? ""
  property string lastKey: ""                  // station the switch resumes

  function popupShown() {
    MpdService.error = "";
    MpdService.run(stationsProc, ["--stations"]);
  }

  function play(key) {
    lastKey = key;
    MpdService.load(key, ["--radio", key]);
  }

  // Header switch: stop, or resume the last station (the first one otherwise).
  function setActive(on) {
    if (!on) MpdService.stop();
    else play(stationKey || lastKey || stations[0]?.key || "");
  }

  onStationKeyChanged: if (stationKey !== "") lastKey = stationKey

  Component.onCompleted: MpdService.run(stationsProc, ["--stations"])

  Process {
    id: stationsProc
    stdout: StdioCollector {
      onStreamFinished: root.stations = MpdService.parse(text) ?? []
    }
  }
}
