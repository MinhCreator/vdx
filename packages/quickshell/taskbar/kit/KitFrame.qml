import QtQuick
import qs.config

// Popup body: flat dark surface, a thin light frame, sharp corners, a padded
// column. Children stack vertically and take `width: parent.width`.
Rectangle {
  id: root

  default property alias content: column.data
  property int padding: 16

  implicitWidth: Theme.popupWidth
  implicitHeight: column.implicitHeight + 2 * padding
  color: Theme.background0
  border.width: Theme.windowFrameWidth
  border.color: Theme.frame

  Column {
    id: column
    x: root.padding
    y: root.padding
    width: root.width - 2 * root.padding
    spacing: 14
  }
}
