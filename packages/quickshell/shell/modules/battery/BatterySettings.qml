import QtQuick
import qs.bar
import qs.config
import qs.kit

// Battery options in the Shell Manager.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "battery" }

  KitToggleRow { visible: ModuleSettings.get("battery", "text", "content") === "content"; module: "battery"; key: "percent"; label: "Show charge"; hint: "Off: icon only" }
}
