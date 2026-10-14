import QtQuick
import qs.config

// Popup header: an icon, a bold title and a small-caps subtitle with " · "
// between its parts; badges / buttons / a switch on the right (children).
Item {
  id: root

  property string icon: ""               // kit/icons name; wins over glyph
  property string glyph: ""
  property color glyphColor: Theme.foreground0
  property string title: ""
  property string subtitle: ""
  property color subtitleColor: Theme.muted

  default property alias actions: actionRow.data

  width: parent ? parent.width : 0
  implicitHeight: Math.max(caption.implicitHeight, actionRow.height)

  Item {
    id: icon
    anchors { left: parent.left; verticalCenter: caption.verticalCenter }
    width: 30
    height: 24

    KitIcon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== ""
      name: root.icon
      tint: root.glyphColor
      size: 24
    }

    KitText {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon === ""
      text: root.glyph
      color: root.glyphColor
      font.pixelSize: Theme.fontSize + 9
    }
  }

  Column {
    id: caption
    anchors {
      left: icon.right; leftMargin: 8
      right: actionRow.left; rightMargin: actionRow.width > 0 ? 10 : 0
    }
    spacing: 3

    KitText {
      width: parent.width
      text: root.title
      elide: Text.ElideRight
      font.pixelSize: Theme.fontSize + 3
      font.weight: Font.ExtraBold
    }

    KitText {
      width: parent.width
      visible: root.subtitle !== ""
      text: root.subtitle
      color: root.subtitleColor
      elide: Text.ElideRight
      font.pixelSize: Theme.fontSize - 2
      font.letterSpacing: 1
    }
  }

  Row {
    id: actionRow
    anchors { right: parent.right; verticalCenter: caption.verticalCenter }
    spacing: 8
  }
}
