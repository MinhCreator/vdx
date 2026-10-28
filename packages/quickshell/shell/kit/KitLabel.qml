import QtQuick
import qs.config

// Section caption in small caps with an optional value on the right and, under it,
// `about`: one line on what the block does and when it applies (every block has one)
// ("ACTIVE AREA ............ 100% · 147 mm", without the dots).
Item {
  id: root

  readonly property bool isKitLabel: true   // KitGrouper: starts a group
  property string text: ""
  property string value: ""
  property color valueColor: Theme.muted
  property string about: ""

  width: parent ? parent.width : 0
  implicitHeight: caption.implicitHeight + (about !== "" ? aboutText.implicitHeight + Theme.gapTight : 0)

  KitText {
    id: caption
    text: root.text
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }

  KitText {
    id: aboutText
    visible: root.about !== ""
    anchors { left: parent.left; right: parent.right; top: caption.bottom; topMargin: Theme.gapTight }
    text: root.about
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 1
    wrapMode: Text.WordWrap
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
