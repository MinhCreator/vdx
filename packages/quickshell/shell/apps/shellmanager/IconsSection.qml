import QtQuick
import qs.config
import qs.kit

// Appearance › SHAPE, under the corners: the icon set for the whole shell —
// Material or Phosphor (outline or solid), or Lucide (outline only). The group's label lives
// in AppearancePage.
KitColumn {
  spacing: Theme.gapGroup

  KitRow {
    wide: true
    label: "Icon set"
    hint: "Everywhere in the shell"

    KitSegments {
      model: [
        { label: "Material", value: "material" },
        { label: "Phosphor", value: "phosphor" },
        { label: "Lucide",   value: "lucide" }
      ]
      current: ShellSettings.iconSet
      onPicked: value => ShellSettings.set("iconSet", value)
    }
  }

  KitRow {
    wide: true
    visible: ShellSettings.iconSet !== "lucide"
    label: "Icon style"

    KitSegments {
      model: [
        { label: "Outline", value: false },
        { label: "Solid",   value: true }
      ]
      current: ShellSettings.solidIcons
      onPicked: value => ShellSettings.set("solidIcons", value)
    }
  }

  KitGrouper {}
}
