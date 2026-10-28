import QtQuick
import qs.config

// Section caption in small caps with an optional value on the right and, beside it,
// `about`: what the block does, dim on the same line
// ("ACTIVE AREA ............ 100% · 147 mm", without the dots).
Item {
  id: root

  readonly property bool isKitLabel: true   // KitGrouper: starts a group
  property string text: ""
  property string value: ""
  property color valueColor: Theme.muted
  property string about: ""

  width: parent ? parent.width : 0
  implicitHeight: caption.implicitHeight

  KitText {
    id: caption
    text: root.text
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }

  // what the block does: on the caption's line, smaller and darker than the caption
  KitText {
    id: aboutText
    visible: root.about !== "" && root.value === ""
    anchors { left: caption.right; leftMargin: Theme.gapWide; right: parent.right; verticalCenter: caption.verticalCenter }
    text: root.about
    color: Theme.dim
    elide: Text.ElideRight
    font.pixelSize: Theme.fontSize - 3
  }

  // a long value ends in … rather than running into the caption
  KitText {
    anchors { left: caption.right; leftMargin: Theme.gapWide; right: parent.right; verticalCenter: caption.verticalCenter }
    horizontalAlignment: Text.AlignRight
    elide: Text.ElideRight
    text: root.value
    color: root.valueColor
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }
}
