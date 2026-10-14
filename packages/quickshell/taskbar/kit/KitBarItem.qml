import QtQuick
import qs.config

// A bar module's face: an SVG icon and a short text, both in `tint`. Either
// part may be empty. Extra children (a click area, a badge) overlay it.
Item {
  id: root

  property string icon: ""
  property string text: ""
  property color tint: Theme.foreground0

  implicitWidth: row.implicitWidth
  implicitHeight: Math.max(row.implicitHeight, Theme.fontSize + 4)

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: 6

    KitIcon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== ""
      name: root.icon
      tint: root.tint
      size: Theme.fontSize + 2
      solid: ShellSettings.solidIcons
    }

    KitText {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.text !== ""
      text: root.text
      color: root.tint
    }
  }
}
