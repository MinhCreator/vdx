import QtQuick
import Quickshell
import qs.bar.island
import qs.config

// Bar module: the sound as an equalizer while a track is loaded (nothing
// otherwise: it takes no room). Paused, it stays as a flat row unless
// Modules › Equalizer › Show when paused is off. No clicks: the player is the
// music module's.
Item {
  id: root

  required property PanelWindow bar

  readonly property bool shown: IslandService.hasMedia
    && (IslandService.playing || ModuleSettings.get("equalizer", "showPaused", true))

  implicitWidth: shown ? bars.implicitWidth : 0
  implicitHeight: Theme.fontSize + 4

  EqualizerBars {
    id: bars
    anchors.verticalCenter: parent.verticalCenter
    visible: root.shown
    height: Theme.fontSize
  }
}
