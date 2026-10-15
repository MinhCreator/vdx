import QtQuick
import qs.config
import qs.kit

// Brightness options in the Shell Manager.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitToggleRow { module: "brightness"; key: "percent"; label: "Brightness in the bar"; hint: "Off: the icon alone" }
}
