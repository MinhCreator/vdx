import QtQuick
import qs.config
import qs.kit

// Workspaces options in the Shell Manager.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitOptionRow {
    module: "workspaces"; key: "style"; fallback: "numbers"
    label: "Workspaces as"; hint: "How each workspace is drawn"
    model: [
      { label: "Digits", value: "numbers" },
      { label: "Squares", value: "squares" },
      { label: "Dots", value: "dots" },
      { label: "Dashes", value: "dashes" }
    ]
  }
}
