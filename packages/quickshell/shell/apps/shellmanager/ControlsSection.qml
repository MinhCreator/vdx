import QtQuick
import qs.config
import qs.kit

// Appearance › STYLE (with IconsSection and CornersSection): outlined (framed
// controls, the terminal look) or material (filled controls, no frames, a quiet
// hairline round popups). Changing it turns the password dots on; the switch
// below turns them off again. The group's label lives in AppearancePage.
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
      onPicked: value => {
        if (value !== ShellSettings.material) ShellSettings.set("passwordDots", true);
        ShellSettings.set("material", value);
      }
    }
  }

  KitRow {
    label: "Password dots"
    hint: "Dots, not squares, in password fields"

    KitSwitch {
      checked: ShellSettings.passwordDots
      onToggled: ShellSettings.set("passwordDots", !ShellSettings.passwordDots)
    }
  }
}
