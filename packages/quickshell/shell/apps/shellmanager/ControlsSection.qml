import QtQuick
import qs.config
import qs.kit

// Appearance › CONTROLS: outlined (framed controls, the terminal look) or
// material (filled controls, no frames, a quiet hairline round popups), and
// the password dots, which the user sets on their own. The label lives in AppearancePage.
Column {
  spacing: Theme.gapGroup

  KitRow {
    wide: true
    label: "Controls"
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

  KitRow {
    label: "Password dots"
    hint: "Off: squares"

    KitSwitch {
      checked: ShellSettings.passwordDots
      onToggled: ShellSettings.set("passwordDots", !ShellSettings.passwordDots)
    }
  }
}
