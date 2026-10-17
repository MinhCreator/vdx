import QtQuick
import qs.config
import qs.kit

// Notifications options in the Shell Manager: the popup. The unseen dot is a
// Bar option (Bar › Style › Notifications dot): on the Folder, or the island's pill.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "POPUP" }

  KitOptionRow {
    module: "notifications"; key: "rows"; fallback: 6
    label: "Rows before scrolling"; hint: "How tall the history gets"
    model: [{ label: "4", value: 4 }, { label: "6", value: 6 }, { label: "10", value: 10 }]
  }

  KitToggleRow { module: "notifications"; key: "closeOnClear"; fallback: false; label: "Close after clear"; hint: "Off: the popup stays open" }
}
