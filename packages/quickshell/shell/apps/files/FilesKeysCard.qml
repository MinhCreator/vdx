import QtQuick
import qs.config
import qs.kit

// The keys of the window (F1).
KitFrame {
  id: root

  readonly property var keyRows: [
    { key: "enter", action: "open, or pick in a picker" },
    { key: "backspace", action: "the folder above" },
    { key: "alt + ← →", action: "back and forward" },
    { key: "↑ ↓ (grid: ← →)", action: "move; with shift, extend" },
    { key: "Ctrl + A, C, X, V", action: "select all, copy, cut, paste" },
    { key: "Ctrl + Z / Shift + Z", action: "undo, redo" },
    { key: "Delete", action: "move to trash" },
    { key: "Shift + Delete", action: "delete for good" },
    { key: "F2", action: "rename" },
    { key: "Ctrl + N / D", action: "new folder, pin this folder" },
    { key: "Ctrl + S", action: "star or unstar" },
    { key: "a letter", action: "jump to a name" },
    { key: "Ctrl + F", action: "focus the search" },
    { key: "Ctrl + K", action: "search all of Home, or this folder" },
    { key: "Ctrl + H / G", action: "hidden files, grid view" },
    { key: "Ctrl + L", action: "type a path" },
    { key: "space", action: "show or hide the preview" },
    { key: "f5", action: "read the folder again" },
    { key: "esc", action: "clear, close" },
  ]

  KitHeader { icon: "keyboard"; title: "Keys" }

  KitLine {}

  Repeater {
    model: root.keyRows

    Row {
      required property var modelData
      width: root.width - 2 * root.padding
      spacing: Theme.gapMedium

      KitText {
        width: 150
        text: modelData.key
        font.pixelSize: Theme.fontSize - 1
      }

      KitText {
        width: parent.width - 150 - parent.spacing
        text: modelData.action
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }
    }
  }
}
