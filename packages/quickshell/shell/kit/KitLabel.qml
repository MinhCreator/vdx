import QtQuick
import qs.config

// Section caption in small caps with an optional value on the right and, beside it,
// `about`: what the block does and when it applies, in an info bubble on hover
// ("ACTIVE AREA ............ 100% · 147 mm", without the dots).
Item {
  id: root

  readonly property bool isKitLabel: true   // KitGrouper: starts a group
  z: aboutArea.containsMouse ? 10 : 0         // the bubble opens over the rows below
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

  // the about line hides behind an info mark; hovering it opens the bubble
  KitIcon {
    id: aboutMark
    visible: root.about !== ""
    anchors { left: caption.right; leftMargin: Theme.gapTight; verticalCenter: caption.verticalCenter }
    name: "info"
    size: Theme.iconSmall
    tint: aboutArea.containsMouse ? Theme.foreground1 : Theme.muted

    MouseArea {
      id: aboutArea
      anchors { fill: parent; margins: -4 }
      hoverEnabled: true
    }
  }

  Rectangle {
    visible: aboutArea.containsMouse && root.about !== ""
    z: 10
    x: aboutMark.x
    y: caption.height + Theme.gapTight
    width: Math.min(300, root.width - x)
    height: aboutText.implicitHeight + 2 * Theme.gapMedium
    radius: Theme.radiusCard
    color: Theme.surfaceHigh
    border { width: Theme.hairline; color: Theme.controlLine }

    KitText {
      id: aboutText
      anchors { fill: parent; margins: Theme.gapMedium }
      text: root.about
      color: Theme.foreground1
      font.pixelSize: Theme.fontSize - 1
      wrapMode: Text.WordWrap
    }
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
