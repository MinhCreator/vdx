import QtQuick
import qs.config

// Popup body: flat dark surface, a thin light frame, sharp corners, a padded
// column. Children stack vertically and take `width: parent.width`. A window
// showing the same content sets `framed: false` and its own `padding`.
Rectangle {
  id: root

  default property alias content: column.data
  property int padding: 16
  property bool framed: true

  implicitWidth: Theme.popupWidth
  implicitHeight: column.implicitHeight + 2 * padding
  color: Theme.background0
  border.width: framed ? Theme.windowFrameWidth : 0
  border.color: Theme.frame

  Column {
    id: column
    x: root.padding
    y: root.padding
    width: root.width - 2 * root.padding
    spacing: 14
  }
}
