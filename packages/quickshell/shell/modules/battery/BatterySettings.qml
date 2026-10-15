import QtQuick
import qs.config
import qs.kit

// Battery options in the Shell Manager.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitToggleRow { module: "battery"; key: "percent"; label: "Charge in the bar"; hint: "Off: the icon alone" }
}
