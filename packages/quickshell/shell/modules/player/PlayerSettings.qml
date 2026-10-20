import QtQuick
import qs.bar
import qs.config
import qs.kit

// Player options in the Shell Manager.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "player" }

  KitOptionRow {
    visible: ModuleSettings.get("player", "text", "content") === "content"
    module: "player"; key: "show"; fallback: "both"
    label: "Shows"; hint: "What the bar names while something plays"
    model: [{ label: "Icon", value: "icon" }, { label: "Title", value: "title" }, { label: "Artist", value: "artist" },
            { label: "Both", value: "both" }]
  }

  KitOptionRow {
    visible: ModuleSettings.get("player", "text", "content") === "content" && ModuleSettings.get("player", "show", "both") !== "icon"
    module: "player"; key: "titleLength"; fallback: 60
    label: "Max length"; hint: "Longer ones end with …"
    model: [{ label: "30", value: 30 }, { label: "45", value: 45 }, { label: "60", value: 60 }, { label: "Full", value: -1 }]
  }

  KitGrouper {}
}
