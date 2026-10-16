import QtQuick
import qs.config
import qs.kit

// Appearance › ICONS: outline or solid, for the whole shell.
Column {
  spacing: Theme.gapGroup

  KitLabel {
    text: "ICONS"
    value: ShellSettings.solidIcons ? "SOLID" : "OUTLINE"
  }

  KitRow {
    wide: true
    label: "Style"
    hint: "Everywhere: the bar, popups and windows"

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
