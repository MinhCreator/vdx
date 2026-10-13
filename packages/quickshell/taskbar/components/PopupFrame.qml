import QtQuick
import qs.config

// Root of every popup body: the square rofi-style frame with a padded column
// inside. Children stack vertically and should take `width: parent.width`.
Rectangle {
  id: root

  default property alias content: column.data

  readonly property int inset: Theme.popupFrameWidth + Theme.popupPadding

  implicitWidth: Theme.popupWidth
  implicitHeight: column.implicitHeight + 2 * inset
  color: Theme.background1
  border.width: Theme.popupFrameWidth
  border.color: Theme.frame

  Column {
    id: column
    x: root.inset
    y: root.inset
    width: root.width - 2 * root.inset
    spacing: Theme.popupPadding
  }
}
