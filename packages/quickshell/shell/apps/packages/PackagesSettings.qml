import QtQuick
import qs.config
import qs.kit

// Package manager options in the Shell Manager (ModuleSettings "packages"):
// what opens and when it checks, what is listed, how removing and updating
// behave. The bar module's own row is PackagesBarSettings (Shell apps › BAR).
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "OPENING" }

  KitOptionRow {
    module: "packages"; key: "startTab"; fallback: "updates"
    label: "Opens on"; hint: "The tab shown first"
    model: [{ label: "Updates", value: "updates" }, { label: "Installed", value: "installed" }, { label: "Cache", value: "cache" }]
  }

  KitToggleRow { module: "packages"; key: "checkOnOpen"; label: "Check on open"; hint: "Once in ten minutes at most" }

  KitOptionRow {
    module: "packages"; key: "interval"; fallback: 30
    label: "Background check"; hint: "How often updates are checked"
    model: [{ label: "Off", value: 0 }, { label: "30 min", value: 30 }, { label: "1 h", value: 60 }]
  }

  KitToggleRow { module: "packages"; key: "aur"; label: "Include the AUR"; hint: "Counted and listed with the repos" }

  KitLine {}

  KitLabel { text: "LIST" }

  KitOptionRow {
    module: "packages"; key: "sortBy"; fallback: "name"
    label: "Sort installed by"; hint: "Name, size, or newest first"
    model: [{ label: "Name", value: "name" }, { label: "Size", value: "size" }, { label: "Newest", value: "date" }]
  }

  KitOptionRow {
    module: "packages"; key: "cacheView"; fallback: "old"
    label: "Cache shows"; hint: "Old versions, or all cached"
    model: [{ label: "Old", value: "old" }, { label: "All", value: "all" }]
  }

  KitLine {}

  KitLabel { text: "SAFETY" }

  KitToggleRow { module: "packages"; key: "confirm"; label: "Ask before uninstalling"; hint: "Uninstall asks “Sure?” once" }
}
