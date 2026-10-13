import QtQuick
import qs.config

// Read-only level in the slider's style: "LABEL ........ value" caption, a
// filled track (0..1) and an optional dim note under it.
Column {
  id: root

  property string label: ""
  property string text: ""
  property string note: ""
  property real value: 0
  property color tint: Theme.foreground0

  spacing: 4

  Item {
    width: parent.width
    height: caption.implicitHeight

    ThemeText {
      id: caption
      text: root.label
      color: Theme.dim
      font.pixelSize: Theme.fontSize - 2
      font.letterSpacing: 1
    }

    ThemeText {
      anchors { right: parent.right; verticalCenter: caption.verticalCenter }
      text: root.text
      color: root.tint
      font.pixelSize: Theme.fontSize - 1
    }
  }

  Rectangle {
    width: parent.width
    height: 6
    color: Theme.background2

    Rectangle {
      width: Math.max(0, Math.min(1, root.value)) * parent.width
      height: parent.height
      color: root.tint
    }
  }

  ThemeText {
    visible: root.note !== ""
    text: root.note
    color: Theme.dim
    font.pixelSize: Theme.fontSize - 2
  }
}
