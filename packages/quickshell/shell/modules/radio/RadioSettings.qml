import QtQuick
import qs.config
import qs.kit

// Radio options in the Shell Manager.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitOptionRow {
    module: "radio"; key: "titleLength"; fallback: 60
    label: "Title in the bar"; hint: "Longer ones end with …"
    model: [{ label: "30", value: 30 }, { label: "45", value: 45 }, { label: "60", value: 60 }, { label: "Off", value: 0 }]
  }
}
