import QtQuick
import qs.kit

// Windows options in the bar's module settings: when the popup closes by itself.
Column {
  spacing: 14

  KitToggleRow { module: "windows"; key: "closeOnMode"; fallback: false; label: "Close after mode"; hint: "Off: the popup stays open" }
  KitToggleRow { module: "windows"; key: "closeOnGrid"; fallback: false; label: "Close after grid"; hint: "Off: the popup stays open" }
}
