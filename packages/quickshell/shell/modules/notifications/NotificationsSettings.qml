import QtQuick
import qs.config
import qs.kit

// Notifications options in the Shell Manager: the bar's unseen dot (BAR: on the
// Folder, or the island's pill) and the popup (POPUP).
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitRow {
    label: "Unseen dot"
    hint: "Marks unseen notifications"

    KitSwitch {
      checked: ShellSettings.barFolderDot
      onToggled: ShellSettings.set("barFolderDot", !checked)
    }
  }

  KitRow {
    wide: true
    label: "Dot colour"
    hint: ""
    visible: ShellSettings.barFolderDot

    // a colour dot per choice, pushed to the right edge (laid out right to left,
    // so the model runs backwards); the picked one carries a ring
    Row {
      spacing: Theme.gapMedium
      layoutDirection: Qt.RightToLeft

      Repeater {
        model: ["blue", "green", "yellow", "red", "theme"]

        Rectangle {
          id: swatch
          required property string modelData
          readonly property bool picked: ShellSettings.barDotColor === modelData
            || (modelData === "theme" && ShellSettings.barDotColor === "light")

          anchors.verticalCenter: parent.verticalCenter
          width: 18
          height: 18
          radius: Theme.pill(height)
          color: Theme.notifyDot(modelData)
          border.width: picked ? 2 : 0
          border.color: Theme.foreground0

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ShellSettings.set("barDotColor", swatch.modelData)
          }
        }
      }
    }
  }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitOptionRow {
    module: "notifications"; key: "rows"; fallback: 6
    label: "Rows before scrolling"; hint: "How tall the history gets"
    model: [{ label: "4", value: 4 }, { label: "6", value: 6 }, { label: "10", value: 10 }]
  }

  KitToggleRow { module: "notifications"; key: "closeOnClear"; fallback: false; label: "Close after clear"; hint: "Off: the popup stays open" }
}
