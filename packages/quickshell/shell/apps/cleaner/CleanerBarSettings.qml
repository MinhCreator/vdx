import QtQuick
import qs.kit

// The cleaner's bar popup options (Shell apps › Bar module): how many of the
// biggest categories it lists.
Column {
  spacing: 14

  KitLabel { text: "POPUP" }

  KitOptionRow {
    module: "cleaner"; key: "biggest"; fallback: 6
    label: "Categories listed"; hint: "The biggest, in the bar's popup"
    model: [{ label: "3", value: 3 }, { label: "6", value: 6 }, { label: "10", value: 10 }]
  }
}
