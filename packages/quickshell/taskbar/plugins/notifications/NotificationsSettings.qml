import QtQuick
import qs.config
import qs.kit

// Notifications options in the Shell Manager: the bell, then the popup.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitToggleRow { plugin: "notifications"; key: "dot"; label: "Unread dot"; hint: "A red square on the bell for unseen ones" }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitOptionRow {
    plugin: "notifications"; key: "rows"; fallback: 6
    label: "Rows before scrolling"; hint: "How tall the history gets"
    model: [{ label: "4", value: 4 }, { label: "6", value: 6 }, { label: "10", value: 10 }]
  }
}
