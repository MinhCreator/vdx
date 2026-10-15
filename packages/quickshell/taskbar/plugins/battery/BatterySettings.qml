import QtQuick
import qs.config
import qs.kit

// Battery options in the Shell Manager.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitToggleRow { plugin: "battery"; key: "percent"; label: "Charge in the bar"; hint: "off: the icon alone" }
}
