import QtQuick
import qs.bar
import qs.config
import qs.kit

// Music options in the Shell Manager.
KitColumn {
  spacing: Theme.gapGroup

  // the old "Off" length (0) was the icon alone: it is Shows › Icon now
  Component.onCompleted: if (ModuleSettings.get("music", "titleLength", 60) === 0) {
    ModuleSettings.set("music", "show", "icon");
    ModuleSettings.set("music", "titleLength", 60);
  }

  KitLabel { text: "BAR" }
  BarTextRow { module: "music" }

  KitOptionRow {
    visible: ModuleSettings.get("music", "text", "content") !== "name"
    module: "music"; key: "show"; fallback: "both"
    label: "Shows"; hint: ""
    model: [{ label: "Icon", value: "icon" }, { label: "Title", value: "title" }, { label: "Artist", value: "artist" },
            { label: "Both", value: "both" }]
  }

  KitOptionRow {
    visible: ModuleSettings.get("music", "text", "content") !== "name" && ModuleSettings.get("music", "show", "both") !== "icon"
    module: "music"; key: "titleLength"; fallback: 60
    label: "Max length"; hint: "Longer ones end with …"
    model: [{ label: "30", value: 30 }, { label: "45", value: 45 }, { label: "60", value: 60 }, { label: "Full", value: -1 }]
  }
}
