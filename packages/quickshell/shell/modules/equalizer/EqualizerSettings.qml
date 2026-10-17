import QtQuick
import qs.config
import qs.kit

// Equalizer options in the Shell Manager: the bars' colour, a dot per choice
// like the notifications dot; the gradients run from the left bar to the right.
KitColumn {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitRow {
    label: "Colour"
    hint: "Sea and sunset: gradients"

    // a dot per choice, pushed to the right edge (laid out right to left,
    // so the model runs backwards); the picked one carries a ring
    Row {
      spacing: Theme.gapMedium
      layoutDirection: Qt.RightToLeft

      Repeater {
        model: ["sunset", "sea", "blue", "green", "yellow", "red", "theme"]

        Rectangle {
          id: swatch
          required property string modelData
          readonly property var colours: Theme.equalizerColours(modelData)
          readonly property bool picked: ModuleSettings.get("equalizer", "colour", "theme") === modelData

          anchors.verticalCenter: parent.verticalCenter
          width: 18
          height: 18
          radius: Theme.pill(height)
          border.width: picked ? 2 : 0
          border.color: Theme.foreground0
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: swatch.colours[0] }
            GradientStop { position: 1; color: swatch.colours[1] }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: ModuleSettings.set("equalizer", "colour", swatch.modelData)
          }
        }
      }
    }
  }
}
