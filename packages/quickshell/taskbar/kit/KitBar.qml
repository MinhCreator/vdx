import QtQuick
import qs.config

// Thin level bar (signal, usage): the filled part in `tint` over the track.
Rectangle {
  id: root

  property real value: 0                 // 0..1
  property color tint: Theme.foreground0

  width: parent ? parent.width : 0
  implicitHeight: 3
  color: Theme.background3

  Rectangle {
    width: Math.max(0, Math.min(1, root.value)) * parent.width
    height: parent.height
    color: root.tint

    Behavior on width { NumberAnimation { duration: 200 } }
  }
}
