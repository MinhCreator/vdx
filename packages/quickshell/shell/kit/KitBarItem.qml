import QtQuick
import qs.config

// A bar module's face: an SVG icon and a short text, both in `tint`. Either
// part may be empty. Extra children (a click area, a badge) overlay it. A
// new tint (a state turning red, a value coming back) fades in (Motion.bar).
Item {
  id: root

  property string icon: ""
  property string text: ""
  property color tint: Theme.foreground0
  property color shownTint: tint
  Behavior on shownTint { enabled: Motion.bar; ColorAnimation { duration: Motion.slow } }

  implicitWidth: row.implicitWidth
  implicitHeight: Math.max(row.implicitHeight, Theme.fontSize + 4)

  Row {
    id: row
    anchors.verticalCenter: parent.verticalCenter
    spacing: Theme.gapSmall

    KitIcon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== ""
      name: root.icon
      tint: root.shownTint
      size: Theme.fontSize + 2 + ShellSettings.barIconGrow
    }

    KitText {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.text !== ""
      text: root.text
      color: root.shownTint
    }
  }
}
