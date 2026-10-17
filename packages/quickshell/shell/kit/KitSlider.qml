import QtQuick
import qs.config

// Thin slider: a 3px track, the filled part in `tint`, a square knob. It never
// writes `value` itself: drag and click emit moved(value) for live
// changes (volume), and released(value) fires once when a drag ends (seeking).
// While pressed it shows the pointer position (`shown`).
// `snaps` (0..1 each, ascending): the stops the knob locks to, drawn as ticks;
// Empty: continuous. The wheel is left to the page: it scrolls, never slides.
Item {
  id: root

  property real value: 0                 // 0..1
  property bool dimmed: false
  property color tint: Theme.foreground0
  property var snaps: []
  property var spectrum: []              // colours laid along the track, instead of the fill

  // the default tint takes the accent (Appearance › Accent › Sliders); a
  // state colour passed in (a load, a battery) keeps its own
  readonly property bool accented: !dimmed && tint === Theme.foreground0 && Theme.accentOn("sliders")
  readonly property color fill: dimmed ? Theme.gray : accented ? Theme.accent : tint
  readonly property bool pressed: area.pressed
  property real dragValue: 0
  readonly property real shown: Math.max(0, Math.min(1, pressed ? dragValue : value))
  readonly property real knobSize: 12

  signal moved(real value)
  signal released(real value)

  function nearest(v) {
    return snaps.length === 0 ? v : snaps.reduce((best, s) => Math.abs(s - v) < Math.abs(best - v) ? s : best, snaps[0]);
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
    radius: Theme.pill(height)
    color: Theme.background3
    clip: true

    // a spectrum (a colour picker's ramp): the track is its colours, no fill
    Row {
      visible: root.spectrum.length > 0
      width: parent.width
      height: parent.height
      Repeater {
        model: root.spectrum

        Rectangle {
          required property color modelData
          width: parent.width / root.spectrum.length
          height: parent.height
          color: modelData
        }
      }
    }

    Rectangle {
      visible: root.spectrum.length === 0
      width: root.shown * parent.width
      height: parent.height
      radius: parent.radius
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: root.fill }
        GradientStop { position: 1; color: root.accented ? Theme.accentEnd : root.fill }
      }
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
      radius: Theme.pill(width)
      color: Theme.gray
    }
  }

  Rectangle {
    readonly property int size: area.containsMouse || root.pressed ? 14 : 12
    width: size
    height: size
    radius: Theme.pill(size)
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
  }
}
