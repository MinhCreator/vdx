import QtQuick
import qs.kit
import qs.config

// The clipboard's bar popup options (Shell apps › Bar module): how much of
// the history it lists and what it keeps on screen. The window is not affected.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "POPUP" }

  KitOptionRow {
    module: "clipboard"; key: "rows"; fallback: 0
    label: "Entries listed"; hint: "Newest first, rest scrolls"
    model: [{ label: "5", value: 5 }, { label: "10", value: 10 }, { label: "All", value: 0 }]
  }

  KitToggleRow { module: "clipboard"; key: "search"; label: "Search field"; hint: "Narrows the list as you type" }

  KitToggleRow { module: "clipboard"; key: "closeOnCopy"; label: "Close after copying"; hint: "Off: the popup stays open" }

  KitToggleRow { module: "clipboard"; key: "closeOnOpen"; label: "Close popup on open"; hint: "When its window opens" }
}
