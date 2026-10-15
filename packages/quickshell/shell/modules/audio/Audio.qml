import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit

// Bar module: output volume ("--" while muted); wheel changes it.
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  KitBarItem {
    id: label
    icon: AudioService.muted ? "volume-x" : AudioService.headphones ? "headphones" : "volume"
    text: !ModuleSettings.get("audio", "percent", true) ? "" : AudioService.muted ? "--" : String(Math.min(Theme.audioMaxPercent, AudioService.volume))
    tint: AudioService.muted ? Theme.red : Theme.foreground0
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
      open: popup.visible
    }
  }
}
