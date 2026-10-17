import QtQuick
import qs.bar
import qs.config
import qs.kit

// Brightness options in the Shell Manager.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "brightness" }

  KitToggleRow { visible: ModuleSettings.get("brightness", "text", "content") !== "name"; module: "brightness"; key: "percent"; label: "Show brightness"; hint: "Off: icon only" }
}
