import QtQuick
import qs.bar
import qs.config
import qs.kit

// Notifications options in the Shell Manager, by what they decide: how a new one
// arrives (NEW NOTIFICATIONS: a card or a live line, how long), its avatar's colour
// (APP COLOURS), the history popup (CENTRE), the mark for the unseen (UNSEEN: the dot
// on the island's pill or the Folder) and the Notifications bar module (BELL: its
// unseen mark).
KitColumn {
  spacing: Theme.sectionGap

  KitLabel { text: "NEW NOTIFICATIONS" }

  KitOptionRow {
    enabled: Theme.island; dimmed: !enabled
    module: "notifications"; key: "appear"; fallback: "card"
    label: "Show as"; hint: "A toast on the island, or a line in its live slot"
    model: [{ label: "Card", value: "card" }, { label: "Live activity", value: "live" }]
  }

  // a card (and a toast) stays this long; a live line has its own time in Bar › Live
  KitOptionRow {
    enabled: !Theme.island || ModuleSettings.get("notifications", "appear", "card") === "card"; dimmed: !enabled
    module: "notifications"; key: "toastSeconds"; fallback: 5
    label: "Card stays for"; hint: enabled ? "Critical ones always stay" : "Cards only: a live line has its own time in Bar › Live"
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
    label: "Dot while tucked away"
    hint: "On the Folder or the island's pill when the bell is not on the bar"

    KitSwitch {
      checked: ShellSettings.barFolderDot
      onToggled: ShellSettings.set("barFolderDot", !checked)
    }
  }

  KitRow {
    label: "Dot colour"
    hint: "Theme: the text colour"
    enabled: ShellSettings.barFolderDot; dimmed: !enabled

    KitSwatches {
      model: ["blue", "green", "yellow", "red", "theme"]
      picked: ShellSettings.barDotColor === "light" ? "theme" : ShellSettings.barDotColor
      colours: name => [Theme.notifyDot(name), Theme.notifyDot(name)]
      onChosen: name => ShellSettings.set("barDotColor", name)
    }
  }

  KitLine {}

  KitLabel { text: "BELL" }

  KitOptionRow {
    module: "notifications"; key: "badge"; fallback: "off"
    label: "Unseen mark"; hint: "On the bell while something is unseen. Off: it only lights up"
    model: [{ label: "Off", value: "off" }, { label: "Dot", value: "dot" }, { label: "Count", value: "count" }]
  }

  KitLine {}

  KitGrouper {}
}
