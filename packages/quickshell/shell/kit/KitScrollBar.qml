import QtQuick
import QtQuick.Controls
import qs.config

// Two-pixel transient thumb, with a wider invisible pointer target.
ScrollBar {
  id: root
  policy: ScrollBar.AsNeeded
  implicitWidth: 8
  minimumSize: 0.06
  padding: 3
  hoverEnabled: true
  opacity: size < 1 && (active || hovered || pressed) ? 1 : 0
  Behavior on opacity { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }
  contentItem: Rectangle {
    implicitWidth: 2
    implicitHeight: 20
    radius: Theme.pill(width)
    color: root.pressed ? Theme.foreground2 : Theme.outline
  }
  background: Item {}
}
