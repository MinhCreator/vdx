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
    text: Theme.iconBrightness + " " + BrightnessService.brightness
    color: BrightnessService.nightActive ? Theme.orange : Theme.foreground0
  }

  // Wheel events reach a layer-shell surface only through a MouseArea.
  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
    onWheel: wheel => {
      if (wheel.angleDelta.y !== 0)
        BrightnessService.stepBrightness(wheel.angleDelta.y > 0 ? Theme.brightnessScrollStep : -Theme.brightnessScrollStep);
    }
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "brightness"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    BrightnessPopup {
      id: content
      anchors.fill: parent
    }
  }
}
