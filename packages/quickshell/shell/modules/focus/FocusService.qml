pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Focus: mako's do-not-disturb mode. The bar module and the hub's tile read `on`
// and call `toggle()`; the island's toasts keep quiet while it is on (critical
// ones still come).
Singleton {
  id: root

  property bool on: false

  function toggle() {
    set.command = ["makoctl", "mode", on ? "-r" : "-a", "do-not-disturb"];
    set.running = true;
    on = !on;
  }

  function refresh() { if (!read.running) read.running = true; }

  Process {
    id: read
    command: ["makoctl", "mode"]
    running: true
    stdout: StdioCollector { onStreamFinished: root.on = text.split("\n").includes("do-not-disturb") }
  }
  Process { id: set }

  // another tool may flip the mode: look again now and then
  Timer { interval: 15000; running: true; repeat: true; onTriggered: root.refresh() }
}
