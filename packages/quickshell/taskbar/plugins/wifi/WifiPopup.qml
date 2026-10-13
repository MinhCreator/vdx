import QtQuick
import qs.components
import qs.config

PopupFrame {
  id: root

  signal closeRequested()

  focus: true
  Keys.onEscapePressed: WifiService.view === "list" ? root.closeRequested() : WifiService.showList()

  WifiHeader { width: parent.width }

  PopupSeparator { width: parent.width }

  Column {
    width: parent.width
    visible: WifiService.view === "list"
    spacing: Theme.popupPadding

    WifiInfoPanel { width: parent.width }
    PopupSeparator { width: parent.width }
    WifiDnsSection { width: parent.width }
    PopupSeparator { width: parent.width }
    WifiNetworkList { width: parent.width }
  }

  WifiPasswordView {
    width: parent.width
    visible: WifiService.view === "password"
  }

  WifiSpeedtestView {
    width: parent.width
    visible: WifiService.view === "speedtest"
  }
}
