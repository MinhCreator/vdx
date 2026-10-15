import QtQuick
import qs.config
import qs.kit

// Wifi options in the Shell Manager.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitToggleRow { plugin: "wifi"; key: "name"; label: "Network name in the bar"; hint: "Off: the icon alone" }
}
