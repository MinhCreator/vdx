import QtQuick
import qs.config
import qs.kit

// Header of the nested views (password, speed test): what the view is about
// and a Back button to the list.
KitHeader {
  readonly property bool password: WifiService.view === "password"

  icon: password ? "lock" : "gauge"
  title: password ? "Connect" : "Speed test"
  subtitle: password ? (WifiService.selected?.ssid ?? "").toUpperCase()
    : WifiService.speedtestBusy ? "MEASURING…"
    : WifiService.speedtestError !== "" ? "FAILED"
    : WifiService.speedtest ? "DONE · " + (WifiService.speedtest.server || "").toUpperCase() : ""

  KitButton {
    icon: "arrow-left"
    text: "Back"
    onClicked: WifiService.showList()
  }
}
