import QtQuick
import qs.config
import qs.kit

// Wifi options in the Shell Manager.
Column {
  spacing: 14

  KitToggleRow { plugin: "wifi"; key: "name"; label: "Network name in the bar"; hint: "off: the icon alone" }
}
