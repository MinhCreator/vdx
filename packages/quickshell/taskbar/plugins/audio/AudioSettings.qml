import QtQuick
import qs.config
import qs.kit

// Audio options in the Shell Manager.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitToggleRow { plugin: "audio"; key: "percent"; label: "Volume in the bar"; hint: "Off: the icon alone" }
}
