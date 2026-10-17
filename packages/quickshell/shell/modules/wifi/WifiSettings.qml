import QtQuick
import qs.bar
import qs.config
import qs.kit

// Wifi options in the Shell Manager.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "wifi" }

  KitToggleRow { visible: ModuleSettings.get("wifi", "text", "content") === "content"; module: "wifi"; key: "name"; label: "Show network name"; hint: "Off: icon only" }
}
