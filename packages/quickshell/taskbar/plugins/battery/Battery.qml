import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit

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

  KitBarItem {
    id: label
    icon: BatteryService.saver ? "leaf" : BatteryService.charging ? "battery-charging"
        : BatteryService.plugged ? "plug" : "battery"
    text: String(BatteryService.capacity)
    tint: BatteryService.saver ? Theme.aqua
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
