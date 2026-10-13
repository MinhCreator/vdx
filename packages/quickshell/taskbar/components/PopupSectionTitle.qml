import QtQuick
import qs.config

// Section title with an optional control (a switch, a status) on the right.
Item {
  id: root

  property string text: ""

  default property alias trailing: slot.data

  implicitHeight: Math.max(title.implicitHeight, slot.childrenRect.height)

  ThemeText {
    id: title
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    text: root.text
    font.letterSpacing: 1
  }

  Item {
    id: slot
    anchors { right: parent.right; verticalCenter: parent.verticalCenter }
    width: childrenRect.width
    height: childrenRect.height
  }
}
