import QtQuick
import qs.config
import qs.kit

// Workspaces options in the Shell Manager.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitOptionRow {
    plugin: "workspaces"; key: "style"; fallback: "numbers"
    label: "Workspaces as"; hint: "Numbers, or a small square each"
    model: [{ label: "Numbers", value: "numbers" }, { label: "Squares", value: "squares" }]
  }
}
