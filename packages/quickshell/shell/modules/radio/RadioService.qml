pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.mpd

// Internet radio on top of MpdService: stations from radio-cli's
// stations.json. The bar module and the popup read MpdService for playback and
// this service for the stations.
Singleton {
  id: root

  readonly property bool active: MpdService.source === "radio" && !MpdService.stopped

  // The station the music pushed out of the queue (music.sh keeps its key): the radio stands paused —
  // a station is a stream, there is nothing to keep but its name — and play brings it back. A stop of
  // the radio itself holds nothing.
  readonly property string heldKey: MpdService.player.heldRadio || ""
  readonly property bool held: heldKey !== "" && !active
  function release() { MpdService.control(["--release-radio"]); }

  property var stations: []                    // [{key, name, genre, about}]
  readonly property string stationKey: stations.find(s => s.name === MpdService.player.station)?.key ?? ""
  property string lastKey: ""                  // station the switch resumes
  // the one a play brings back: on air, else the held one, else the last
  readonly property string resumeKey: active ? stationKey : (heldKey || lastKey)

  // the station on air, else the one the switch resumes (its name; "" before the list is read)
  readonly property string stationName: stations.find(s => s.key === resumeKey)?.name ?? ""

  // ---- favourites: the station keys starred in the Music window (music.favoriteStations) ----
  readonly property var favorites: ModuleSettings.get("music", "favoriteStations", [])
  readonly property var favoriteStations: stations.filter(s => favorites.includes(s.key))

  function isFavorite(key) { return favorites.includes(key); }

  function setFavorite(key, on) {
    const rest = favorites.filter(k => k !== key);
    ModuleSettings.set("music", "favoriteStations", on ? rest.concat([key]) : rest);
  }

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
    else play(resumeKey || stations[0]?.key || "");
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
