import QtQuick
import qs.config
import qs.kit

// Appearance › STYLE (with CornersSection and ControlsSection): outline or solid
// icons, for the whole shell. The group's label lives in AppearancePage.
Column {
  spacing: Theme.gapGroup

  KitRow {
    wide: true
    label: "Icons"
    hint: "Bar, popups and windows"

    KitChoices {
      stretch: true
      model: [
        { label: "Outline", value: false },
        { label: "Solid",   value: true }
      ]
      current: ShellSettings.solidIcons
      onPicked: value => ShellSettings.set("solidIcons", value)
    }
  }
}
