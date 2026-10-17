import QtQuick
import qs.bar
import qs.config
import qs.kit

// Battery options in the Shell Manager.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "battery" }

  KitOptionRow {
    visible: ModuleSettings.get("battery", "text", "content") === "content"
    module: "battery"; key: "shows"; fallback: "both"
    label: "Shows"
    model: [{ label: "Icon and charge", value: "both" }, { label: "Charge only", value: "charge" }]
  }
}
