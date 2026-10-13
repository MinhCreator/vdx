import QtQuick
import qs.components
import qs.config

Row {
  id: root

  readonly property real columnWidth: (width - spacing) / 2
  readonly property bool measured: WifiService.connected && WifiService.pingMs > 0

  spacing: 16

  PopupInfoList {
    width: root.columnWidth
    model: [
      { label: "PING",
        value: root.measured ? Math.round(WifiService.pingMs) + " ms" : "—",
        color: Theme.pingColor(WifiService.pingMs) },
      { label: "RECEIVING",  value: Theme.humanRate(WifiService.down) },
      { label: "DOWNLOADED", value: Theme.humanSize(WifiService.downTotal) },
      { label: "IP",         value: WifiService.ipAddress || "—" }
    ]
  }

  PopupInfoList {
    width: root.columnWidth
    model: [
      { label: "LOSS",
        value: root.measured ? WifiService.packetLoss + " %" : "—",
        color: root.measured ? Theme.qualityColor(WifiService.packetLoss, 0, 5) : Theme.muted },
      { label: "SENDING",  value: Theme.humanRate(WifiService.up) },
      { label: "UPLOADED", value: Theme.humanSize(WifiService.upTotal) },
      { label: "GATEWAY",  value: WifiService.gateway || "—" }
    ]
  }
}
