import QtQuick
import qs.config
import qs.kit

// Brightness options in the Shell Manager.
Column {
  spacing: 14

  KitToggleRow { plugin: "brightness"; key: "percent"; label: "Brightness in the bar"; hint: "off: the icon alone" }
}
