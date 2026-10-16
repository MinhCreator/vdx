import QtQuick
import qs.config
import qs.kit

// The window mode — tiling, floating (like Windows) or scrolling (like Niri).
// Its options live in the Shell Manager › Windows; in the floating mode
// Super + H / J / K / L place the active window.
KitFrame {
  id: root

  readonly property var ws: WindowsService
  readonly property var mode: ws.current

  // the grid was done: Windows closes the popup when its option says so
  signal arranged()
  // a mode was picked: Windows closes the popup when its option says so
  signal modePicked()

  KitHeader {
    icon: "app-window"
    title: "Windows"
    subtitle: root.mode.label.toUpperCase() + (root.ws.active ? " · " + (root.ws.active.lastIpcObject?.class ?? root.ws.active.title ?? "").toUpperCase() : "")
  }

  KitLine {}

  // ---- mode ----
  Column {
    width: parent.width
    spacing: 8

    KitLabel { text: "MODE" }

    KitChoices {
      width: parent.width
      stretch: true
      model: root.ws.choices
      current: root.ws.mode
      onPicked: value => { root.ws.setMode(value); root.modePicked(); }
    }

    KitText {
      width: parent.width
      wrapMode: Text.WordWrap
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
      text: root.mode.about
    }
  }

  // ---- grid ----
  // floating only: the windows of this workspace, spread over the screen in a grid
  Column {
    visible: root.ws.mode === "floating"
    width: parent.width
    spacing: 8

    KitLine {}

    KitLabel { text: "ARRANGE" }

    KitButton {
      icon: "grid"
      text: "Arrange in grid"
      onClicked: {
        root.ws.arrangeGrid();
        root.arranged();
      }
    }

    KitText {
      width: parent.width
      wrapMode: Text.WordWrap
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
      text: "Every window of this workspace, side by side"
    }
  }
}
