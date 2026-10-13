import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config

Item {
  id: root

  required property PanelWindow bar

  readonly property string icon: BatteryService.saver ? Theme.iconLeaf
    : BatteryService.charging ? Theme.iconBatteryCharging
    : BatteryService.plugged ? Theme.iconPlug
    : Theme.iconBatteryLevels[Math.min(4, Math.floor(BatteryService.capacity / 20))]

  visible: BatteryService.present
  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText {
    id: label
    text: root.icon + " " + BatteryService.capacity
    color: BatteryService.saver ? Theme.aqua
         : BatteryService.charging ? Theme.green
         : BatteryService.capacity <= Theme.batteryCritical ? Theme.red
         : BatteryService.capacity <= Theme.batteryWarning ? Theme.yellow
         : Theme.foreground0
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "battery"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: BatteryService.popupShown()

    BatteryPopup {
      id: content
      anchors.fill: parent
      icon: root.icon
    }
  }
}
