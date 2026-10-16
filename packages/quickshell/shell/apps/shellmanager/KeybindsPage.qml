import QtQuick
import qs.config
import qs.kit

// Keybinds in the Shell Manager (ModuleSettings "keybinds"; the panel itself
// is apps/keybinds/Keybinds.qml, Super+B): the panel as the launcher's — rows
// before the list scrolls, its width and where it sits — then the tab it
// opens on and the search's clearing.
Column {
  id: root

  function opt(key, fallback) { return ModuleSettings.get("keybinds", key, fallback); }

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "keyboard"
  readonly property string title: "Keybinds"
  readonly property string subtitle: root.opt("rows", 8) + " ROWS · " + String(root.opt("size", "medium")).toUpperCase()
                                     + " · " + String(root.opt("position", "top")).toUpperCase()

  // no groups for the sidebar
  readonly property var jumps: []

  spacing: 14

  KitLabel { text: "LAYOUT" }

  KitOptionRow {
    module: "keybinds"; key: "rows"; fallback: 8
    label: "Rows"; hint: "Items shown before the list scrolls"
    model: [6, 8, 10, 12].map(v => ({ label: String(v), value: v }))
  }

  KitOptionRow {
    module: "keybinds"; key: "size"; fallback: "medium"
    label: "Size"; hint: "The panel's width"
    model: [{ label: "Small", value: "small" }, { label: "Medium", value: "medium" }, { label: "Large", value: "large" }]
  }

  KitOptionRow {
    module: "keybinds"; key: "position"; fallback: "top"
    label: "Position"; hint: "Where the panel sits on the screen"
    model: [{ label: "Top", value: "top" }, { label: "Center", value: "center" }, { label: "Bottom", value: "bottom" }]
  }

  KitLine {}

  KitLabel { text: "OPENING" }

  KitOptionRow {
    module: "keybinds"; key: "opens"; fallback: "mode"
    label: "Opens on"; hint: "The tab shown first"
    model: [{ label: "Mode", value: "mode" }, { label: "Windows", value: "windows" }, { label: "Desktop", value: "desktop" }, { label: "Media", value: "media" }]
  }

  KitToggleRow { module: "keybinds"; key: "clear"; fallback: true; label: "Clear search on close"; hint: "Off: the search stays as it was" }

  KitToggleRow { module: "keybinds"; key: "english"; fallback: true; label: "English layout on open"; hint: "Switches the keyboard when it opens" }
}
