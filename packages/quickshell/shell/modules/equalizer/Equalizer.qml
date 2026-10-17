import QtQuick
import Quickshell
import qs.bar.island
import qs.config

// Bar module: the sound as an equalizer while a track is loaded (nothing
// otherwise: it takes no room). Click: the player — the island's in the
// island style, the Music popup on the strip. Middle click: play / pause.
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

  MouseArea {
    anchors { fill: parent; margins: -4 }
    enabled: IslandService.hasMedia
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.MiddleButton) IslandService.togglePlay();
      else if (Theme.island) IslandService.requested("media", root.bar.screen?.name ?? "");
      else Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "music", "toggle"]);
    }
  }
}
