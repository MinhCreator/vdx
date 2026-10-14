import QtQuick
import qs.config
import qs.kit

// Notifications options in the Shell Manager.
Column {
  spacing: 14

  KitOptionRow {
    plugin: "notifications"; key: "rows"; fallback: 6
    label: "Rows before scrolling"; hint: "how tall the history gets"
    model: [{ label: "4", value: 4 }, { label: "6", value: 6 }, { label: "10", value: 10 }]
  }

  KitToggleRow { plugin: "notifications"; key: "dot"; label: "Unread dot"; hint: "a red square on the bell for unseen ones" }
}
