import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config

Item {
  id: root

  required property PanelWindow bar

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText {
    id: label
    text: AudioService.icon + " " + (AudioService.muted ? "--" : Math.min(Theme.audioMaxPercent, AudioService.volume))
    color: AudioService.muted ? Theme.red : Theme.foreground0
  }

  // Wheel events reach a layer-shell surface only through a MouseArea.
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
    onWheel: wheel => {
      if (wheel.angleDelta.y !== 0)
        AudioService.stepVolume(wheel.angleDelta.y > 0 ? Theme.audioScrollStep : -Theme.audioScrollStep);
    }
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "audio"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    AudioPopup {
      id: content
      anchors.fill: parent
    }
  }
}
