import QtQuick
import qs.config
import qs.kit

// Appearance › CONTROLS: outlined (framed controls, the terminal look) or
// material (filled controls, no frames, a quiet hairline round popups).
Column {
  spacing: Theme.gapGroup

  KitLabel {
    text: "CONTROLS"
    value: ShellSettings.material ? "MATERIAL" : "OUTLINED"
  }

  KitRow {
    wide: true
    label: "Style"
    hint: "Material: filled, no frames"

    KitChoices {
      stretch: true
      model: [
        { label: "Outlined", value: false },
        { label: "Material", value: true }
      ]
      current: ShellSettings.material
      onPicked: value => ShellSettings.set("material", value)
    }
  }
}
