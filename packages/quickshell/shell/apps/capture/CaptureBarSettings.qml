import QtQuick
import qs.bar
import qs.config
import qs.kit

// Capture's bar module options (Apps › Bar module): the face only. The popup
// has the same choices as the app's window.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "capture" }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitToggleRow {
    module: "capture"; key: "detached"; fallback: false
    label: "Own window"; hint: "Under the bar, not from the island"
  }

  KitGrouper {}
}
