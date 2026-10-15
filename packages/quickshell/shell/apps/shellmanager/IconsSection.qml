import QtQuick
import qs.config
import qs.kit

// Appearance › ICONS: outline or solid, sharp or rounded, for the whole shell.
Column {
  id: root


  spacing: 14

  KitLabel {
    id: iconsGroup
    text: "ICONS"
    value: (ShellSettings.solidIcons ? "SOLID" : "OUTLINE") + (ShellSettings.roundIcons ? " · ROUNDED" : " · SHARP")
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

  KitRow {
    wide: true
    label: "Corners"
    hint: "Line ends and corners of every icon"

    KitChoices {
      stretch: true
      model: [
        { label: "Sharp",   value: false },
        { label: "Rounded", value: true }
      ]
      current: ShellSettings.roundIcons
      onPicked: value => ShellSettings.set("roundIcons", value)
    }
  }
}
