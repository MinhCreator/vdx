import QtQuick
import qs.bar
import qs.config
import qs.kit

// Notifications options in the Shell Manager, by what they decide: how a new one
// arrives (NEW NOTIFICATIONS: a card or a live line, how long), its avatar's colour
// (APP COLOURS), the history popup (CENTRE), the mark for the unseen (UNSEEN: the dot
// on the island's pill or the Folder) and the Notifications bar module (BELL: its
// text and badge).
KitColumn {
  spacing: Theme.sectionGap

  KitLabel { text: "NEW NOTIFICATIONS" }

  KitOptionRow {
    visible: Theme.island
    module: "notifications"; key: "appear"; fallback: "card"
    label: "Show as"; hint: "A toast on the island, or a line in its live slot"
    model: [{ label: "Card", value: "card" }, { label: "Live activity", value: "live" }]
  }

  KitOptionRow {
    module: "notifications"; key: "toastSeconds"; fallback: 5
    label: "Stay for"; hint: "Critical ones always stay"
    model: [{ label: "3 s", value: 3 }, { label: "5 s", value: 5 }, { label: "10 s", value: 10 }, { label: "Stay", value: 0 }]
  }

  KitLine {}

  NotificationsColours { width: parent.width }

  KitLine {}

  KitLabel { text: "CENTRE" }

  KitOptionRow {
    module: "notifications"; key: "rows"; fallback: 6
    label: "Notifications shown"; hint: "Before the list scrolls"
    model: [{ label: "4", value: 4 }, { label: "6", value: 6 }, { label: "10", value: 10 }]
  }

  KitToggleRow { module: "notifications"; key: "closeOnClear"; fallback: false; label: "Close after clear"; hint: "Off: the centre stays open" }

  KitLine {}

  KitLabel { text: "UNSEEN" }

  KitRow {
    label: "Show the dot"
    hint: "On the island's pill, or the Folder, while there is something unseen"

    KitSwitch {
      checked: ShellSettings.barFolderDot
      onToggled: ShellSettings.set("barFolderDot", !checked)
    }
  }

  KitRow {
    label: "Dot colour"
    hint: "Theme: the text colour"
    visible: ShellSettings.barFolderDot

    KitSwatches {
      model: ["blue", "green", "yellow", "red", "theme"]
      picked: ShellSettings.barDotColor === "light" ? "theme" : ShellSettings.barDotColor
      colours: name => [Theme.notifyDot(name), Theme.notifyDot(name)]
      onChosen: name => ShellSettings.set("barDotColor", name)
    }
  }

  KitLine {}

  KitLabel { text: "BELL" }
  BarTextRow { module: "notifications" }

  KitOptionRow {
    module: "notifications"; key: "badge"; fallback: "off"
    label: "Bell badge"; hint: "On the Notifications bar module. Off: the bell only tints"
    model: [{ label: "Off", value: "off" }, { label: "Dot", value: "dot" }, { label: "Count", value: "count" }]
  }

  KitLine {}

  KitGrouper {}
}
