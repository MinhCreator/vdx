import QtQuick
import qs.config

// Thin level bar (signal, usage): the filled part in `tint` over the track.
Rectangle {
  id: root

  property real value: 0                 // 0..1
  property color tint: Theme.foreground0

  width: parent ? parent.width : 0
  implicitHeight: 3
  radius: Theme.pill(height)
  color: Theme.background3

  Rectangle {
    width: Math.max(0, Math.min(1, root.value)) * parent.width
    height: parent.height
    radius: parent.radius
    color: root.tint

    Behavior on width { enabled: Motion.controls; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }
  }
}
