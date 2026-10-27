import QtQuick
import qs.bar
import qs.kit
import qs.config

// Windows options in the bar's module settings: when the popup closes by itself.
Column {
  spacing: Theme.sectionGap

  KitLabel { text: "BAR" }
  BarTextRow { module: "windows" }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitToggleRow { module: "windows"; key: "closeOnMode"; fallback: false; label: "Close after picking a mode"; hint: "Off: popup stays open" }
  KitToggleRow { module: "windows"; key: "closeOnGrid"; fallback: false; label: "Close after the grid"; hint: "Off: popup stays open" }

  KitGrouper {}
}
