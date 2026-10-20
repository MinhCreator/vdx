import QtQuick
import qs.config

// Material (Appearance › Controls): turns a filled control (a field, a select)
// into the Material 3 filled field — square lower corners and a line along the
// bottom, thicker and bright while `active`. Put it first in the control: it
// fills the parent, under the control's content. Outlined: nothing.
Item {
  id: root

  property bool active: false

  anchors.fill: parent
  visible: Theme.material

  // the lower corners squared: the parent's own fill, over its round ones
  Rectangle {
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    height: Math.min(parent.height / 2, root.parent.radius)
    color: root.parent.color
  }

  Rectangle {
    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    height: root.active ? 2 : 1
    color: root.active ? Theme.accentFor("selects", Theme.foreground0) : Theme.gray
    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  }
}
