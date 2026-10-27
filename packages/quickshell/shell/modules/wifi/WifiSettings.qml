import QtQuick
import qs.bar
import qs.config
import qs.kit

// Wifi options in the Shell Manager: what the bar shows (Bar text).
Column {
  spacing: Theme.sectionGap

  KitLabel { text: "BAR" }
  BarTextRow { module: "wifi" }

  KitLine {}

  KitLinkRow {
    label: "Wi-Fi"
    hint: "Networks, DNS, the speed test: Network"
    target: "network"
  }

  KitGrouper {}
}
