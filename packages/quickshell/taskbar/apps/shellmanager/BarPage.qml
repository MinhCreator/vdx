import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar: options only. Groups in one rhythm — a caps title, its rows, a line:
// LAYOUT (Edit bars: the layout is edited on the real bars), MONITORS (one bar
// everywhere or Main / Extra, show bar per monitor), STYLE (icons, every bar).
// Switching a plugin off altogether is on the Plugins page.
Column {
  id: root

  readonly property var names: Quickshell.screens.map(s => s.name)
    .sort((a, b) => (BarLayout.roleOf(a) === "main" ? 0 : 1) - (BarLayout.roleOf(b) === "main" ? 0 : 1))

  spacing: 14

  KitHeader {
    icon: "layout"
    title: "Bar"
    subtitle: Quickshell.screens.filter(s => BarLayout.barOn(s.name)).length + " OF "
      + Quickshell.screens.length + " MONITORS · " + (ShellSettings.solidIcons ? "SOLID ICONS" : "OUTLINE ICONS")
  }

  KitLine {}

  // ---- layout ----------------------------------------------------------------------
  KitLabel { text: "LAYOUT" }

  KitRow {
    label: "Arrange modules"
    hint: "drag modules on the bars themselves; the manager steps aside"

    KitButton {
      icon: "layout"
      text: "Edit bars"
      selected: true
      onClicked: {
        BarLayout.editing = true;
        ShellSettings.managerOpen = false;
      }
    }
  }

  KitLine {}

  // ---- monitors --------------------------------------------------------------------
  KitLabel {
    text: "MONITORS"
    value: Quickshell.screens.length === 1 ? ""
         : BarLayout.shared ? "ONE BAR ON ALL " + Quickshell.screens.length
         : "MAIN AND EXTRA APART"
  }

  KitRow {
    visible: Quickshell.screens.length > 1
    label: "Same bar everywhere"
    hint: BarLayout.shared ? "every monitor shows the Main bar" : "Main and Extra are set up apart"

    KitSwitch {
      checked: BarLayout.shared
      onToggled: BarLayout.setShared(!BarLayout.shared)
    }
  }

  Repeater {
    model: root.names

    KitRow {
      required property string modelData

      width: root.width
      label: modelData + (Quickshell.screens.length > 1 ? " · " + (BarLayout.roleOf(modelData) === "main" ? "Main" : "Extra") : "")
      hint: BarLayout.barOn(modelData)
        ? BarLayout.visibleIn("left", modelData).length + BarLayout.visibleIn("center", modelData).length
          + BarLayout.visibleIn("right", modelData).length + " modules placed"
        : "no bar"

      Row {
        spacing: 12

        KitIcon {
          anchors.verticalCenter: parent.verticalCenter
          name: BarLayout.isInternal(modelData) ? "laptop" : "monitor"
          tint: Theme.muted
        }

        KitSwitch {
          anchors.verticalCenter: parent.verticalCenter
          checked: BarLayout.barOn(modelData)
          onToggled: BarLayout.setBarOn(modelData, !BarLayout.barOn(modelData))
        }
      }
    }
  }

  KitLine {}

  // ---- style (every bar) -------------------------------------------------------------
  KitLabel { text: "STYLE" }

  KitRow {
    label: "Icons"
    hint: "outlines or filled shapes, on every bar"

    KitChoices {
      model: [
        { label: "Outline", value: false },
        { label: "Solid",   value: true }
      ]
      current: ShellSettings.solidIcons
      onPicked: value => ShellSettings.set("solidIcons", value)
    }
  }
}
