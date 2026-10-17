import QtQuick
import Quickshell
import qs.bar.island
import qs.config

// Bar module: the sound as an equalizer while a track is loaded (nothing
// otherwise: it takes no room). No clicks: the player is the music module's.
Item {
  id: root

  required property PanelWindow bar

  implicitWidth: IslandService.hasMedia ? bars.implicitWidth : 0
  implicitHeight: Theme.fontSize + 4

  EqualizerBars {
    id: bars
    anchors.verticalCenter: parent.verticalCenter
    visible: IslandService.hasMedia
    height: Theme.fontSize
  }
}
