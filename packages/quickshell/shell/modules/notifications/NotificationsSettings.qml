import QtQuick
import qs.bar
import qs.config
import qs.kit

// Notifications options in the Shell Manager: the bar (BAR: the module's text; BELL:
// the bell's own badge; UNSEEN DOT: the dot on the Folder or the island's pill) and
// the history popup (HISTORY).
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "notifications" }

  KitLine {}

  KitLabel { text: "BELL" }

  KitOptionRow {
    module: "notifications"; key: "badge"; fallback: "off"
    label: "Bell badge"; hint: "Off: the bell only tints"
    model: [{ label: "Off", value: "off" }, { label: "Dot", value: "dot" }, { label: "Count", value: "count" }]
  }

  KitLine {}

  KitLabel { text: "UNSEEN DOT" }

  KitRow {
    label: "Show the dot"
    hint: "On the Folder, or the island's pill, while the centre is tucked away"

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

  KitLabel { text: "TOASTS" }

  KitOptionRow {
    module: "notifications"; key: "toastSeconds"; fallback: 5
    label: "Toast duration"; hint: "Stay: until dismissed. Critical always stays"
    model: [{ label: "3 s", value: 3 }, { label: "5 s", value: 5 }, { label: "10 s", value: 10 }, { label: "Stay", value: 0 }]
  }

  KitLine {}

  KitLabel { text: "HISTORY" }

  KitOptionRow {
    module: "notifications"; key: "rows"; fallback: 6
    label: "Notifications shown"; hint: "Before the list scrolls"
    model: [{ label: "4", value: 4 }, { label: "6", value: 6 }, { label: "10", value: 10 }]
  }

  KitToggleRow { module: "notifications"; key: "closeOnClear"; fallback: false; label: "Close after clear"; hint: "Off: the popup stays open" }

  KitGrouper {}
}
