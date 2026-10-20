import QtQuick
import qs.config
import qs.kit

// Tray options in the Shell Manager: the icons folded away.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitToggleRow {
    module: "tray"; key: "collapsed"; fallback: false
    label: "Collapse"; hint: "Icons behind a dots button"
  }

  KitGrouper {}
}
