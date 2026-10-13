import QtQuick
import qs.config

// Square horizontal slider: framed track, filled part and a square knob. It
// never writes `value` itself: drag, click and wheel emit moved(value) for live
// changes (volume), and released(value) fires once when a drag ends (seeking).
// While pressed the slider shows the pointer position (`shown`).
Item {
  id: root

  property real value: 0                 // 0..1
  property bool dimmed: false
  property real wheelStep: 0.05

  readonly property color tint: dimmed ? Theme.muted : Theme.foreground0
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
  implicitHeight: 20
  opacity: enabled ? 1 : 0.4

  Rectangle {
    id: track
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: 6
    color: "transparent"
    border.width: 1
    border.color: area.containsMouse || area.pressed ? Theme.foreground1 : Theme.muted

    Rectangle {
      width: root.shown * parent.width
      height: parent.height
      color: root.tint
    }
  }

  Rectangle {
    width: 6
    height: Theme.switchKnob
    anchors.verticalCenter: parent.verticalCenter
    x: root.shown * (root.width - width)
    color: root.tint
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
