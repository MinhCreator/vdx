import QtQuick
import qs.config
import qs.kit

// Battery options in the Shell Manager.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitToggleRow { module: "battery"; key: "percent"; label: "Show charge"; hint: "Off: icon only" }
}
