import QtQuick
import qs.config
import qs.kit

// Package manager options in the Shell Manager (ModuleSettings "packages"):
// what opens and when it checks, what is listed, how removing and updating
// behave. The bar module's own row is PackagesBarSettings (Shell apps › BAR).
Column {
  spacing: 14

  KitLabel { text: "OPENING" }

  KitOptionRow {
    module: "packages"; key: "startTab"; fallback: "updates"
    label: "Start on"; hint: "The tab the window opens on"
    model: [{ label: "Updates", value: "updates" }, { label: "Installed", value: "installed" }, { label: "Cache", value: "cache" }]
  }

  KitToggleRow { module: "packages"; key: "checkOnOpen"; label: "Check on open"; hint: "Once in ten minutes at most" }

  KitOptionRow {
    module: "packages"; key: "interval"; fallback: 30
    label: "Background check"; hint: "How often the updates are looked up"
    model: [{ label: "30 min", value: 30 }, { label: "1 h", value: 60 }, { label: "Off", value: 0 }]
  }

  KitToggleRow { module: "packages"; key: "aur"; label: "Include the AUR"; hint: "Counted and listed with the repos" }

  KitLine {}

  KitLabel { text: "LISTS" }

  KitOptionRow {
    module: "packages"; key: "sortBy"; fallback: "name"
    label: "Sort installed by"; hint: "Name, size, or newest first"
    model: [{ label: "Name", value: "name" }, { label: "Size", value: "size" }, { label: "Newest", value: "date" }]
  }

  KitOptionRow {
    module: "packages"; key: "cacheView"; fallback: "old"
    label: "Cache shows"; hint: "Old versions, or every cached one"
    model: [{ label: "Old", value: "old" }, { label: "All", value: "all" }]
  }

  KitLine {}

  KitLabel { text: "REMOVING AND UPDATING" }

  KitToggleRow { module: "packages"; key: "confirm"; label: "Ask before uninstalling"; hint: "Uninstall asks “Sure?” once" }

  KitRow {
    wide: true
    label: "Update command"
    hint: "Runs in a terminal, asks in the panel"

    KitInput {
      width: Theme.controlWidth
      text: ModuleSettings.get("packages", "updateCommand", PackagesService.defaultUpdate)
      onAccepted: ModuleSettings.set("packages", "updateCommand", text)
    }
  }
}
