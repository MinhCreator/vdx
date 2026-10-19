import QtQuick
import qs.bar
import qs.config
import qs.kit

// Radio options in the Shell Manager.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "radio" }

  KitOptionRow {
    visible: ModuleSettings.get("radio", "text", "content") === "content"
    module: "radio"; key: "show"; fallback: "title"
    label: "Shows"; hint: ""
    model: [{ label: "Icon", value: "icon" }, { label: "Title", value: "title" }]
  }

  KitOptionRow {
    visible: ModuleSettings.get("radio", "text", "content") === "content" && ModuleSettings.get("radio", "show", "title") !== "icon"
    module: "radio"; key: "titleLength"; fallback: 60
    label: "Max length"; hint: "Longer ones end with …"
    model: [{ label: "30", value: 30 }, { label: "45", value: 45 }, { label: "60", value: 60 }, { label: "Full", value: -1 }]
  }
}
