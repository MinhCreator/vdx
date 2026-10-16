import QtQuick
import qs.kit
import qs.config

// The task manager's bar module options (Shell apps › BAR, under the
// module's place): how much its popup lists.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "POPUP" }

  KitOptionRow {
    module: "taskmanager"; key: "popupRows"; fallback: 5
    label: "Programs listed"; hint: "The busiest, in the bar's popup"
    model: [{ label: "3", value: 3 }, { label: "5", value: 5 }, { label: "8", value: 8 }]
  }

  KitToggleRow { module: "taskmanager"; key: "closeOnOpen"; label: "Close popup on open"; hint: "When its window opens" }
}
