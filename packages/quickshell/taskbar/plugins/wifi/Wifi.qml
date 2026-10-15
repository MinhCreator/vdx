import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit

Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  readonly property string name: WifiService.ssid.length > Theme.wifiBarMaxLength
    ? WifiService.ssid.slice(0, Theme.wifiBarMaxLength - 1) + Theme.ellipsis
    : WifiService.ssid

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  KitBarItem {
    id: label
    icon: WifiService.radioOn ? "wifi" : "wifi-off"
    text: !PluginSettings.get("wifi", "name", true) ? "" : WifiService.connected ? root.name : "--"
    tint: WifiService.connected ? Theme.green : Theme.gray
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "wifi"
    closeOnEscape: false                 // WifiPopup: Escape goes back, then closes
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: WifiService.popupShown()
    onHidden: WifiService.popupHidden()

    WifiPopup {
      id: content
      anchors.fill: parent
      onCloseRequested: popup.visible = false
    }
  }
}
