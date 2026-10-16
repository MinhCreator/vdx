import QtQuick
import qs.kit
import qs.config

// The package manager's bar module options (Shell apps › BAR, under the
// module's place): what the icon shows and what its popup lists.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "ICON" }

  KitToggleRow { module: "packages"; key: "showCount"; label: "Count on the icon"; hint: "The number of pending updates" }

  KitToggleRow { module: "packages"; key: "tint"; label: "Yellow when pending"; hint: "The number turns yellow" }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitOptionRow {
    module: "packages"; key: "popupRows"; fallback: 6
    label: "Updates listed"; hint: "The first ones, the rest in the window"
    model: [{ label: "3", value: 3 }, { label: "6", value: 6 }, { label: "10", value: 10 }]
  }

  KitToggleRow { module: "packages"; key: "popupRollback"; label: "Roll back button"; hint: "Rolls back the last upgrade" }

  KitToggleRow { module: "packages"; key: "closeOnOpen"; label: "Close popup on open"; hint: "When its window opens" }
}
