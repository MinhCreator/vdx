import QtQuick
import qs.config

// "LABEL ........ value" line; the value elides before it reaches the label.
Item {
  id: root

  property string label: ""
  property string value: ""
  property color valueColor: Theme.foreground0

  implicitHeight: 18

  ThemeText {
    id: labelText
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    text: root.label
    color: Theme.dim
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }

  ThemeText {
    anchors {
      left: labelText.right; leftMargin: 8
      right: parent.right
      verticalCenter: parent.verticalCenter
    }
    text: root.value
    color: root.valueColor
    elide: Text.ElideRight
    horizontalAlignment: Text.AlignRight
    font.pixelSize: Theme.fontSize - 1
  }
}
