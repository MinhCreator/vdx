import QtQuick
import qs.config
import qs.kit

// Music options in the Shell Manager.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitOptionRow {
    plugin: "music"; key: "titleLength"; fallback: 60
    label: "Title in the bar"; hint: "longer ones end with …"
    model: [{ label: "30", value: 30 }, { label: "45", value: 45 }, { label: "60", value: 60 }, { label: "Off", value: 0 }]
  }
}
