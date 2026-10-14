import QtQuick
import qs.components
import qs.config
import qs.kit

// Wi-Fi popup: the overview, or a nested view (password, speed test) by WifiService.view.
KitFrame {
  id: root

  signal closeRequested()

  focus: true
  Keys.onEscapePressed: WifiService.view === "list" ? root.closeRequested() : WifiService.showList()

  WifiHeader {
    width: parent.width
    visible: WifiService.view !== "list"
  }

  WifiOverview {
    width: parent.width
    visible: WifiService.view === "list"
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
