import QtQuick
import Quickshell
import Quickshell.Io

// Background images are optional: a failed or stalled screenshot must still
// reach the session lock. Bound the entire parallel process group, not each
// monitor in turn, and keep a QML fallback for a process that cannot start.
Scope {
  id: root

  readonly property int deadlineMs: 1000
  readonly property int killGraceMs: 200
  property bool busy: false
  signal ready()

  function prepare(directory, screens) {
    if (busy) return false;
    // A previous timed-out worker may still be stopping. Lock immediately
    // with a plain background rather than defer a new request behind it.
    if (worker.running) { ready(); return true; }
    busy = true;
    // Keep bash waiting after TERM: timeout can then escalate against the
    // whole group even when a screenshot process ignores the first signal.
    worker.command = ["timeout", "--kill-after=" + killGraceMs / 1000 + "s", deadlineMs / 1000 + "s",
      "bash", "-c", "trap 'wait' TERM; umask 077; d=$1; shift; mkdir -p \"$d\"; for m; do grim -t jpeg -q 85 -o \"$m\" \"$d/$m.jpg\" & done; wait",
      "lock", directory].concat(screens);
    fallback.restart();
    worker.running = true;
    return true;
  }

  function finish() {
    if (!busy) return;
    fallback.stop();
    busy = false;
    ready();
  }

  Process {
    id: worker
    onExited: root.finish()
  }

  Timer {
    id: fallback
    interval: root.deadlineMs + root.killGraceMs + 100
    onTriggered: {
      worker.running = false;
      root.finish();
    }
  }
}
