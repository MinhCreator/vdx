import QtQuick
import qs.config

// Material + Filled: turns a filled control (a field, a select) into the Material 3
// filled text field — square lower corners and an active indicator along the bottom,
// 1 px surfaceVariantText, 2 px primary while `active`. Put it first in the control: it
// fills the parent, under the control's content. Strict or Outlined: nothing.
Item {
  id: root

  property bool active: false

  anchors.fill: parent
  visible: Theme.m3 && Theme.filled

  // the lower corners squared: the parent's own fill, over its round ones
  Rectangle {
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    height: Math.min(parent.height / 2, root.parent.radius)
    color: root.parent.color
  }

  Rectangle {
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    height: root.active ? 2 : 1
    color: root.active ? Theme.primary : Theme.surfaceVariantText
    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  }
}
