import QtQuick
import qs.config

// Popup body: the language's popup fill (Material a surface container, Strict the
// surface) in a hairline (Theme.popupFrame), Theme.radiusSurface, a padded column. A bar popup opened inside the
// island (`inIsland`, set by the Island) takes the island as its surface and
// frame and draws neither. Children stack vertically and take
// `width: parent.width`. A window showing the same content sets
// `framed: false` and its own `padding`.
Rectangle {
  id: root

  default property alias content: column.data
  property int padding: Theme.popupPadding
  property bool framed: true
  // a window whose first item is a KitHeader: its top sits this much higher
  property int headerInset: 0
  // the same for a window whose last item is text: its line box ends below the ink
  property int bottomInset: 0
  property bool inIsland: false
  // a menu: as wide as its content, not at least Theme.popupWidth (the island's
  // popup width follows this too). The content sets implicitWidth itself.
  property bool fitWidth: false

  implicitWidth: Theme.popupWidth
  implicitHeight: column.implicitHeight + 2 * padding - headerInset - bottomInset
  radius: framed ? Theme.radiusSurface : 0
  color: inIsland ? "transparent" : Theme.popupFill
  border.width: framed && !inIsland ? Theme.windowFrameWidth : 0
  border.color: Theme.popupFrame

  KitColumn {
    id: column
    x: root.padding
    y: root.padding - root.headerInset
    width: root.width - 2 * root.padding
    spacing: Theme.gapGroup
  }
}
