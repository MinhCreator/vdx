import QtQuick
import qs.config
import qs.kit

// The window mode — tiling, floating (like Windows) or scrolling (like Niri) —
// and the active window's place: halves, quarters, thirds, the middle or the
// whole screen, each drawn as a tiny screen with its part filled.
KitFrame {
  id: root

  readonly property var ws: WindowsService
  readonly property var mode: ws.modes.find(m => m.value === ws.mode) ?? ws.modes[0]

  KitHeader {
    icon: root.mode.icon
    title: "Windows"
    subtitle: root.mode.label.toUpperCase() + (root.ws.active ? " · " + (root.ws.active.lastIpcObject?.class ?? root.ws.active.title ?? "").toUpperCase() : "")
  }

  KitLine {}

  // ---- mode
  Column {
    width: parent.width
    spacing: 8

    KitLabel { text: "MODE" }

    KitChoices {
      width: parent.width
      stretch: true
      model: root.ws.modes
      current: root.ws.mode
      onPicked: value => root.ws.setMode(value)
    }

    KitText {
      width: parent.width
      wrapMode: Text.WordWrap
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
      text: root.mode.about
    }
  }

  KitLine {}

  // ---- place
  Column {
    width: parent.width
    spacing: 10

    KitLabel {
      text: "PLACE THE WINDOW"
      value: root.ws.mode === "floating" ? "" : "FLOATS IT"
    }

    Repeater {
      model: [
        [["left", [0, 0, 0.5, 1]], ["right", [0.5, 0, 0.5, 1]], ["top", [0, 0, 1, 0.5]], ["bottom", [0, 0.5, 1, 0.5]],
         ["center", [0.15, 0.1, 0.7, 0.8]], ["maximize", [0, 0, 1, 1]]],
        [["top-left", [0, 0, 0.5, 0.5]], ["top-right", [0.5, 0, 0.5, 0.5]], ["bottom-left", [0, 0.5, 0.5, 0.5]],
         ["bottom-right", [0.5, 0.5, 0.5, 0.5]]],
        [["left-third", [0, 0, 1 / 3, 1]], ["middle-third", [1 / 3, 0, 1 / 3, 1]], ["right-third", [2 / 3, 0, 1 / 3, 1]],
         ["left-two-thirds", [0, 0, 2 / 3, 1]], ["right-two-thirds", [1 / 3, 0, 2 / 3, 1]]]
      ]

      Row {
        required property var modelData
        spacing: 6

        Repeater {
          model: modelData

          SnapTile {
            required property var modelData
            area: modelData[1]
            onPicked: root.ws.snap(modelData[0])
          }
        }
      }
    }
  }
}
