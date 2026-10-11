import QtQuick
import Quickshell
import Quickshell.Io

// custom/brightness (gruvbox): JSON exec every 2s, color foreground0
// (modules.css). brightness.sh outputs {"text":"<icon>  <NN>","class":"on|off"}.
//   on-click       -> brightness.sh --toggle (hyprsunset)
//   on-scroll-up   -> brightnessctl set +5%
//   on-scroll-down -> brightnessctl set 5%-
//
// Interaction mirrors waybar's custom modules with `exec-on-event: true`: the
// label is rebuilt from the action's *own* output instead of waiting for the 2s
// poll. The brightness step and the toggle script both print fresh JSON, so the
// value/icon update within one script run (~40-100 ms) rather than up to 2 s.

Item {
  id: root

  property string text: ""

  // A read is in flight; run once more when it finishes so an update is never
  // dropped because `running` was already true.
  property bool refreshPending: false
  // Wheel steps accumulated while a step process is running (so a fast scroll
  // is never lossy); applied together on the next run.
  property int pendingStep: 0
  property bool stepRunning: false

  function applyJson(raw) {
    try {
      const obj = JSON.parse(raw.trim())
      root.text = obj.text !== undefined ? obj.text : ""
    } catch (e) {
      root.text = ""
    }
  }

  function refresh() {
    if (brightProc.running)
      root.refreshPending = true
    else
      brightProc.running = true
  }

  // Apply the accumulated wheel delta and re-read the value from the same
  // command, so the label reflects the change as soon as it is applied.
  function runStep() {
    if (root.stepRunning || root.pendingStep === 0)
      return
    const s = root.pendingStep
    root.pendingStep = 0
    const arg = s > 0 ? "+" + s + "%" : (-s) + "%-"
    stepProc.command = ["bash", "-c",
      'brightnessctl set "$1" >/dev/null && exec bash "$2"',
      "brightness", arg, Theme.brightnessScript]
    root.stepRunning = true
    stepProc.running = true
  }

  Text {
    id: label
    text: root.text
    color: Theme.foreground0
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  // Periodic poll — picks up external changes (brightness keys, …).
  Process {
    id: brightProc
    command: ["bash", Theme.brightnessScript]
    running: true

    stdout: StdioCollector {
      onStreamFinished: root.applyJson(this.text)
    }

    onExited: {
      if (root.refreshPending) {
        root.refreshPending = false
        brightProc.running = true
      }
    }
  }

  Timer {
    interval: Theme.brightnessIntervalMs
    running: true
    repeat: true
    onTriggered: root.refresh()
  }

  // Night-mode toggle: the script prints the new state after spawning/killing
  // hyprsunset, so the icon flips immediately instead of racing the poll.
  Process {
    id: toggleProc
    command: ["bash", Theme.brightnessScript, "--toggle"]
    stdout: StdioCollector {
      onStreamFinished: root.applyJson(this.text)
    }
  }

  // Scroll: `brightnessctl set` + the script in one command.
  Process {
    id: stepProc
    stdout: StdioCollector {
      onStreamFinished: root.applyJson(this.text)
    }
    onExited: {
      root.stepRunning = false
      root.runStep()   // flush any steps that arrived while this run was busy
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor // waybar: HAND2 when the module has events
    onClicked: toggleProc.running = true
    // A sibling WheelHandler never receives wheel events on a layer-shell
    // surface, so the scroll is handled on the MouseArea (same path as clicks).
    //   on-scroll-up   -> brightnessctl set +5%
    //   on-scroll-down -> brightnessctl set 5%-
    onWheel: (wheel) => {
      const delta = wheel.angleDelta.y
      if (delta === 0)
        return
      root.pendingStep += delta > 0 ? Theme.brightnessScrollStep : -Theme.brightnessScrollStep
      root.runStep()
      wheel.accepted = true
    }
  }
}
