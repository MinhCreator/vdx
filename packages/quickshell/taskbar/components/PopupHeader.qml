import QtQuick
import qs.config

// Popup header shared by every plugin: icon, title and a status line, with
// buttons / a switch on the right (children go there, spaced 8px).
Item {
  id: root

  property string glyph: ""
  property color glyphColor: Theme.foreground0
  property string title: ""
  property string subtitle: ""
  property color subtitleColor: Theme.foreground2

  default property alias actions: actionRow.data

  implicitHeight: Math.max(icon.implicitHeight, caption.implicitHeight)

  ThemeText {
    id: icon
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    text: root.glyph
    color: root.glyphColor
    font.pixelSize: Theme.fontSize + 6
  }

  Column {
    id: caption
    anchors {
      left: icon.right; leftMargin: 10
      right: actionRow.left; rightMargin: actionRow.width > 0 ? 10 : 0
      verticalCenter: parent.verticalCenter
    }
    spacing: 2

    ThemeText { text: root.title }

    ThemeText {
      width: parent.width
      text: root.subtitle
      color: root.subtitleColor
      elide: Text.ElideRight
      font.pixelSize: Theme.fontSize - 3
    }
  }

  Row {
    id: actionRow
    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
    spacing: 8
  }
}
