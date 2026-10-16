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
  // a window whose first item is a KitHeader: its top sits this much higher
  property int headerInset: 0
  // the same for a window whose last item is text: its line box ends below the ink
  property int bottomInset: 0

  implicitWidth: Theme.popupWidth
  implicitHeight: column.implicitHeight + 2 * padding - headerInset - bottomInset
  color: Theme.background0
  border.width: framed ? Theme.windowFrameWidth : 0
  border.color: Theme.frame

  Column {
    id: column
    x: root.padding
    y: root.padding - root.headerInset
    width: root.width - 2 * root.padding
    spacing: 14
  }
}
