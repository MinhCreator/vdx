import QtQuick
import qs.config
import qs.kit

// Icons: the set (Material, Phosphor, Lucide) and the style, for the whole shell.
// The icon section was Appearance › Shape; its keys are the same.
Column {
  id: root
  readonly property Item previewItem: null

  readonly property string icon: "grid"
  readonly property string title: "Icons"
  readonly property string description: "One icon set for the bar, popups and windows."
  readonly property string subtitle: ShellSettings.iconSet.toUpperCase() + " · " + (ShellSettings.solidIcons ? "SOLID" : "OUTLINE")
  readonly property var jumps: []

  readonly property var resetKeys: ["iconSet", "solidIcons"]
  readonly property bool changed: ShellSettings.changed(resetKeys)
  function reset() { ShellSettings.reset(resetKeys); }

  KitLabel { text: "ICONS"; about: "One set for everything; Lucide has outline icons only" }
  IconsSection { width: parent.width }

  KitGrouper {}
}
