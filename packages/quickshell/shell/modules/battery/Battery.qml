import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit

// Bar module: charge with a state icon (charging, plugged, leaf in power saver).
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  visible: BatteryService.present
  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  KitBarItem {
    id: label
    icon: BatteryService.saver ? "leaf" : BatteryService.charging ? "battery-charging"
        : BatteryService.plugged ? "plug" : "battery"
    text: ModuleSettings.get("battery", "percent", true) ? String(BatteryService.capacity) : ""
    tint: BatteryService.saver ? Theme.green
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
    }
  }
}
