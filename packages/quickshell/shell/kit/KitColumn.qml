import QtQuick
import qs.config

// A Column whose rows ease in: a row that shows (an option that depends on
// another, a popup's next view) fades in and the rows under it glide to their
// place. Not while the column itself comes into view — a page or a popup
// opening has its own motion — so it waits a beat after it shows.
Column {
  id: root

  property bool settled: false

  onVisibleChanged: {
    settled = false;
    if (visible) settle.restart();
  }
  Component.onCompleted: if (visible) settle.restart()

  Timer { id: settle; interval: Motion.normal + 50; onTriggered: root.settled = true }

  add: Transition {
    enabled: Motion.controls && root.settled
    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Motion.normal; easing.type: Motion.easing }
  }
  move: Transition {
    enabled: Motion.controls && root.settled
    NumberAnimation { property: "y"; duration: Motion.normal; easing.type: Motion.easing }
    // a row brought in mid-fade by a second change still ends opaque
    NumberAnimation { property: "opacity"; to: 1; duration: Motion.normal; easing.type: Motion.easing }
  }
}
