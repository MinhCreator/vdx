import QtQuick
import qs.config

// Outlined small-caps tag for a header ("12 ONLINE", "PEN + TOUCH").
Rectangle {
  id: root

  property string text: ""
  property color tint: Theme.foreground2

  implicitWidth: label.implicitWidth + 12
  implicitHeight: label.implicitHeight + 4
  color: "transparent"
  border.width: 1
  border.color: Theme.gray

  KitText {
    id: label
    anchors.centerIn: parent
    text: root.text
    color: root.tint
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }
}
