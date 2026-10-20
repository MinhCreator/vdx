import QtQuick
import qs.config
import qs.kit

// Appearance › SHAPE, under the corners: outline or solid icons, for the whole
// shell. The group's label lives in AppearancePage.
Column {
  spacing: Theme.gapGroup

  KitRow {
    wide: true
    label: "Icons"
    hint: "Bar, popups and windows"

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
