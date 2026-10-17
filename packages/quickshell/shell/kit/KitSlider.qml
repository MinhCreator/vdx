import QtQuick
import qs.config

// Thin slider: a 3px track, the filled part in `tint`, a square knob. It never
// writes `value` itself: drag, click and wheel emit moved(value) for live
// changes (volume), and released(value) fires once when a drag ends (seeking).
// While pressed it shows the pointer position (`shown`).
// `snaps` (0..1 each, ascending): the stops the knob locks to, drawn as ticks;
// the wheel moves stop by stop. Empty: continuous.
Item {
  id: root

  property real value: 0                 // 0..1
  property bool dimmed: false
  property color tint: Theme.foreground0
  property real wheelStep: 0.05
  property var snaps: []

  readonly property color fill: dimmed ? Theme.gray : tint
  readonly property bool pressed: area.pressed
  property real dragValue: 0
  readonly property real shown: Math.max(0, Math.min(1, pressed ? dragValue : value))
  readonly property real knobSize: 12

  signal moved(real value)
  signal released(real value)

  function nearest(v) {
    return snaps.length === 0 ? v : snaps.reduce((best, s) => Math.abs(s - v) < Math.abs(best - v) ? s : best, snaps[0]);
  }

  // the value one step away from `value` (dir: 1 or -1)
  function step(dir) {
    if (snaps.length === 0) return value + dir * wheelStep;
    const i = snaps.indexOf(nearest(value));
    return snaps[Math.max(0, Math.min(snaps.length - 1, i + dir))];
  }

  function send(v) {
    dragValue = nearest(Math.max(0, Math.min(1, v)));
    moved(dragValue);
  }

  implicitWidth: 120
  implicitHeight: 18
  opacity: enabled ? 1 : 0.4

  Rectangle {
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 3
    color: Theme.background3

    Rectangle {
      width: root.shown * parent.width
      height: parent.height
      color: root.fill
    }
  }

  // a stop: a tick centred on the knob's position at that value
  Repeater {
    model: root.snaps

    Rectangle {
      required property real modelData
      x: modelData * (root.width - root.knobSize) + root.knobSize / 2 - 1
      anchors.verticalCenter: parent.verticalCenter
      width: 2
      height: 10
      color: Theme.gray
    }
  }

  Rectangle {
    readonly property int size: area.containsMouse || root.pressed ? 14 : 12
    width: size
    height: size
    Behavior on width { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }
    Behavior on height { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }
    anchors.verticalCenter: parent.verticalCenter
    x: root.shown * (root.width - width)
    color: root.fill
    border.width: 2
    border.color: Theme.background0
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    preventStealing: true
    cursorShape: Qt.PointingHandCursor
    onPressed: mouse => root.send(mouse.x / width)
    onPositionChanged: mouse => { if (pressed) root.send(mouse.x / width); }
    onReleased: root.released(root.dragValue)
    onWheel: wheel => root.send(root.step(wheel.angleDelta.y > 0 ? 1 : -1))
  }
}
