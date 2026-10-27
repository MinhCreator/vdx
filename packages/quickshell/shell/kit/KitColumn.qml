import QtQuick
import qs.config

// Rows fade in at their final position. Geometry settles immediately so group
// backgrounds and neighbouring controls share the same layout throughout.
Column {
  id: root

  property bool settled: false

  onVisibleChanged: {
    settled = false;
    if (visible) settle.restart();
  }
  Component.onCompleted: if (visible) settle.restart()

  Timer { id: settle; interval: Motion.normal + 50; onTriggered: root.settled = true }

  // never disabled, only instant: a fade cut short (the column hidden or
  // moved mid-fade, as into the island) still ends opaque
  readonly property bool animate: Motion.controls && settled
  readonly property int duration: animate ? Motion.normal : 0

  add: Transition {
    NumberAnimation { property: "opacity"; from: root.animate ? 0 : 1; to: 1; duration: root.duration; easing.type: Motion.easing }
  }
  move: Transition {
    NumberAnimation { property: "y"; duration: 0 }
    // a row brought in mid-fade by a second change still ends opaque
    NumberAnimation { property: "opacity"; to: 1; duration: root.duration; easing.type: Motion.easing }
  }
}
