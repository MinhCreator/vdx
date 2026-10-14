import QtQuick
import qs.config

// Section caption in small caps with an optional value on the right
// ("ACTIVE AREA ............ 100% · 147 mm", without the dots).
Item {
  id: root

  property string text: ""
  property string value: ""
  property color valueColor: Theme.muted

  width: parent ? parent.width : 0
  implicitHeight: caption.implicitHeight

  KitText {
    id: caption
    text: root.text
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }

  KitText {
    anchors { right: parent.right; verticalCenter: caption.verticalCenter }
    text: root.value
    color: root.valueColor
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }
}
