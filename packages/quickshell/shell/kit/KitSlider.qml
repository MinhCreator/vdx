import QtQuick
import qs.config

// Thin slider: a 3px track, the filled part in `tint`, a square knob. It never
// writes `value` itself: drag, click and wheel emit moved(value) for live
// changes (volume), and released(value) fires once when a drag ends (seeking).
// While pressed it shows the pointer position (`shown`).
Item {
  id: root

  property real value: 0                 // 0..1
  property bool dimmed: false
  property color tint: Theme.foreground0
  property real wheelStep: 0.05

  readonly property color fill: dimmed ? Theme.gray : tint
  readonly property bool pressed: area.pressed
  property real dragValue: 0
  readonly property real shown: Math.max(0, Math.min(1, pressed ? dragValue : value))

  signal moved(real value)
  signal released(real value)

  function send(v) {
    dragValue = Math.max(0, Math.min(1, v));
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
    onWheel: wheel => root.send(root.value + (wheel.angleDelta.y > 0 ? root.wheelStep : -root.wheelStep))
  }
}
