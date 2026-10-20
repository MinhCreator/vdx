import QtQuick
import qs.bar
import qs.kit
import qs.config

// The cleaner's bar popup options (Shell apps › Bar module): how many of the
// biggest categories it lists.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "cleaner"; hasContent: false }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitOptionRow {
    module: "cleaner"; key: "biggest"; fallback: 5
    label: "Categories shown"; hint: "The rest in the window"
    model: [{ label: "3", value: 3 }, { label: "5", value: 5 }, { label: "10", value: 10 }]
  }

  KitToggleRow { module: "cleaner"; key: "closeOnOpen"; label: "Close when its window opens"; hint: "" }

  KitGrouper {}
}
