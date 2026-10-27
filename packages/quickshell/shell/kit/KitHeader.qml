import QtQuick
import qs.config

// Popup header: an icon, a bold title and a small-caps subtitle with " · "
// between its parts; badges / buttons / a switch on the right (children).
// `page`: a window page's own header — in Strict a large title, no icon.
Item {
  id: root

  property string icon: ""               // kit/icons name
  property color iconColor: Theme.foreground0
  property string title: ""
  property string subtitle: ""
  property color subtitleColor: Theme.muted
  property bool page: false
  readonly property bool large: page
  readonly property Item kitCaption: caption

  readonly property bool stackedActions: page && actionRow.implicitWidth + 140 + Theme.gapMedium > width
  default property alias actions: actionRow.data

  width: parent ? parent.width : 0
  implicitHeight: stackedActions ? caption.implicitHeight + Theme.gapMedium + actionRow.height : Math.max(caption.implicitHeight, actionRow.height)

  Item {
    id: icon
    anchors { left: parent.left; verticalCenter: caption.verticalCenter }
    visible: !root.large
    width: visible ? 30 : 0
    height: 24

    KitIcon {
      anchors.verticalCenter: parent.verticalCenter
      name: root.icon
      tint: root.iconColor
      size: Theme.iconLarge
    }
  }

  Column {
    id: caption
    // A shared header height must not leave unused space below the caption.
    y: root.stackedActions ? 0 : Math.max(0, root.height - height)
    anchors {
      left: icon.right; leftMargin: icon.visible ? Theme.gapMedium : 0
      right: root.stackedActions ? parent.right : actionRow.left; rightMargin: !root.stackedActions && actionRow.width > 0 ? 10 : 0
    }
    spacing: root.large ? Theme.gapHair : 3

    KitText {
      width: parent.width
      text: root.title
      elide: Text.ElideRight
      font.pixelSize: Theme.fontSize + (root.large ? 9 : 3)
      font.weight: root.large ? Font.Medium : Font.DemiBold
    }

    KitText {
      width: parent.width
      visible: root.subtitle !== ""
      text: root.subtitle
      color: root.subtitleColor
      elide: Text.ElideRight
      font.pixelSize: Theme.fontSize - 2
      font.letterSpacing: 0.6
    }
  }

  Row {
    id: actionRow
    anchors.right: parent.right
    y: root.stackedActions ? caption.implicitHeight + Theme.gapMedium : caption.y + (caption.implicitHeight - height) / 2
    spacing: Theme.gapMedium
  }
}
