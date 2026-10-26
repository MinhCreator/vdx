import QtQuick
import qs.config
import qs.kit

// A caption over a group of an app's sidebar rows (Files, Music), as Shell Manager's: small, muted, in caps.
Item {
  id: root

  property string text: ""
  property int lead: 0              // the room above it: a group after the first

  width: parent ? parent.width : 0
  height: lead + caption.implicitHeight + Theme.gapHair

  KitText {
    id: caption
    anchors { left: parent.left; leftMargin: Theme.gapWide + 4; top: parent.top; topMargin: root.lead }
    text: Theme.captionCaps ? root.text.toUpperCase() : root.text
    color: Theme.m3 ? Theme.surfaceVariantText : Theme.muted
    font.pixelSize: Theme.textCaption
    font.weight: Font.Medium
    font.letterSpacing: Theme.captionCaps ? 1 : 0
  }
}
