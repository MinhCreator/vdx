import QtQuick
import Quickshell
import Quickshell.Io

// One recording from the delayed start through output verification. The
// request snapshots both the command and the destination; settings changed
// while it runs cannot redirect its result or a later file check.
Scope {
  id: root

  property int startDelay: 240
  property var request: null
  readonly property bool busy: request !== null
  readonly property bool recording: recorder.running
  readonly property bool starting: startTimer.running || launching
  property bool launching: false
  property bool stopping: false
  property bool paused: false
  property real started: 0
  property int elapsed: 0
  property real pausedAt: 0
  property real pausedFor: 0
  property string diagnostic: ""

  signal aboutToStart()
  signal completed(var capture)
  signal failed(var capture, string message)

  function start(capture) {
    if (busy) return false;
    request = Object.assign({}, capture, { command: capture.command.slice() });
    started = 0;
    elapsed = 0;
    paused = false;
    pausedFor = 0;
    stopping = false;
    diagnostic = "";
    startTimer.restart();
    return true;
  }

  function stop() {
    if (startTimer.running) {
      startTimer.stop();
      request = null;
      return;
    }
    if ((!recording && !launching) || stopping) return;
    stopping = true;
    if (recording) recorder.signal(2);
  }

  function togglePause() {
    if (!recording || stopping) return;
    recorder.signal(12);
    if (paused) pausedFor += Date.now() - pausedAt;
    else pausedAt = Date.now();
    paused = !paused;
  }

  Timer {
    id: startTimer
    interval: root.startDelay
    onTriggered: {
      root.launching = true;
      root.started = Date.now();
      root.aboutToStart();
      recorder.command = root.request.command;
      recorder.running = true;
    }
  }

  Timer {
    interval: 500
    running: root.recording
    repeat: true
    onTriggered: {
      if (!root.paused) root.elapsed = Math.max(0, Math.floor((Date.now() - root.started - root.pausedFor) / 1000));
    }
  }

  Process {
    id: recorder
    stderr: StdioCollector { id: recorderErr }
    onStarted: {
      root.launching = false;
      if (root.stopping) recorder.signal(2);
    }
    onExited: code => {
      root.launching = false;
      root.paused = false;
      const lines = recorderErr.text.trim().split("\n");
      root.diagnostic = lines.filter(line => line.includes("gsr error")).pop()?.replace(/^gsr error:\s*/, "")
        || lines.pop() || "gpu-screen-recorder exited with " + code;
      // The recorder may stop with 0, 2 or 130. A non-empty output decides
      // success, matching the recorder's behaviour on an interrupted stop.
      check.running = true;
    }
  }

  Process {
    id: check
    command: ["test", "-s", root.request?.file ?? ""]
    onExited: code => {
      const capture = root.request;
      const message = root.diagnostic;
      root.request = null;
      if (code === 0) root.completed(capture);
      else root.failed(capture, message);
    }
  }
}
