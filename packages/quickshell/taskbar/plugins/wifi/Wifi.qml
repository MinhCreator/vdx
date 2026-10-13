import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config

Item {
  id: root

  required property PanelWindow bar

  readonly property string name: WifiService.ssid.length > Theme.wifiBarMaxLength
    ? WifiService.ssid.slice(0, Theme.wifiBarMaxLength - 1) + Theme.ellipsis
    : WifiService.ssid

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText {
    id: label
    text: Theme.iconWifi + " " + (WifiService.connected ? root.name : "Disconnected")
    color: WifiService.connected ? Theme.green : Theme.gray
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
