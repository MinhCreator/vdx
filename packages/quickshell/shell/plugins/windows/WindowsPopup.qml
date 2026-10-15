import QtQuick
import qs.config
import qs.kit

// The window mode — tiling, floating (like Windows) or scrolling (like Niri).
// Its options live in the Shell Manager › Windows; floating windows are
// placed with Super+arrows and their title bars.
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
}
