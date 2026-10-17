import QtQuick
import qs.config

// The rows of a list already on show, by key, so a row that is new can ease
// in (KitAppear, or an animation of its own): a Repeater over a JS array
// remakes every row on any change, and the known ones should stay as they
// are. Not while the list loads; `reset()` starts afresh (another monitor).
QtObject {
  id: root

  // the Motion part that moves these rows
  property bool motion: Motion.controls
  property bool ready: false
  property var keys: ({})

  // true once per key, for a row that arrives after the list has loaded
  function arrived(key) {
    const fresh = ready && motion && !keys[key];
    keys[key] = true;
    return fresh;
  }

  function reset() {
    ready = false;
    keys = ({});
    settle.restart();
  }

  property Timer settle: Timer { interval: 0; running: true; onTriggered: root.ready = true }
}
