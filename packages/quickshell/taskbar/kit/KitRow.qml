import QtQuick
import qs.config

// A setting row: a label and a dim hint under it on the left, a control (a
// switch, a button, a value) on the right (children).
Item {
  id: root

  property string label: ""
  property string hint: ""
  property color labelColor: Theme.foreground0

  default property alias trailing: slot.data

  width: parent ? parent.width : 0
  implicitHeight: Math.max(text.implicitHeight, slot.height)

  Column {
    id: text
    anchors { left: parent.left; right: slot.left; rightMargin: 12; verticalCenter: parent.verticalCenter }
    spacing: 2

    KitText {
      width: parent.width
      text: root.label
      color: root.labelColor
      elide: Text.ElideRight
    }

    KitText {
      width: parent.width
      visible: root.hint !== ""
      text: root.hint
      color: Theme.muted
      elide: Text.ElideRight
      font.pixelSize: Theme.fontSize - 2
    }
  }

  Row {
    id: slot
    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
    spacing: 8
  }
}
