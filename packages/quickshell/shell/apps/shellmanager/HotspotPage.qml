import QtQuick
import qs.config
import qs.kit
import qs.modules.wifi

// Hotspot: this computer shares its connection over Wi-Fi (NetworkManager). It was the
// Network page's second tab; its keys and backend are the same.
KitColumn {
  id: root
  readonly property Item previewItem: null

  readonly property string icon: "wifi"
  readonly property string title: "Hotspot"
  readonly property string description: "Share this computer's connection over Wi-Fi."
  readonly property string subtitle: !hs?.supported ? "NOT SUPPORTED BY THIS WI-FI CARD" : hs?.active ? "ON · " + hs.clients + " CLIENTS" : "OFF"
  readonly property var jumps: []

  // what the section reads (it was the Network page)
  readonly property var ws: WifiService
  readonly property var hs: ws.hotspot

  spacing: Theme.gapGroup

  onVisibleChanged: {
    if (visible) {
      ws.popupShown();
      ws.refreshHotspot();
    } else {
      ws.popupHidden();
    }
  }

  NetworkHotspot { page: root; width: parent.width }
}
