import QtQuick
import qs.config
import qs.kit

// Wifi options in the Shell Manager.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitToggleRow { module: "wifi"; key: "name"; label: "Show network name"; hint: "Off: icon only" }
}
