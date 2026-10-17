import QtQuick
import qs.config
import qs.kit

// Themes options in the Shell Manager: what the bar shows, how the popup
// looks and how it is driven.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitToggleRow { module: "themes"; key: "name"; fallback: true; label: "Theme name"; hint: "Next to the brush icon" }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitOptionRow {
    module: "themes"; key: "view"; fallback: "auto"
    label: "View"
    hint: "Auto: cards in the island"
    model: [
      { label: "Auto",  value: "auto" },
      { label: "Cards", value: "cards" },
      { label: "List",  value: "list" }
    ]
  }

  KitToggleRow { module: "themes"; key: "wheel"; fallback: true; label: "Wheel picks"; hint: "Over the cards or the list" }
  KitToggleRow { module: "themes"; key: "barWheel"; fallback: true; label: "Wheel on the bar"; hint: "Switches to the next theme" }
}
