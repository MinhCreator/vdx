import QtQuick
import qs.config

// A slider: a track, the part up to the knob filled, a round knob (a functional
// circle: round in Square too). Material: Material 3's — a 4 px track in outlineVariant,
// a 20 px handle. Strict (the boards): a 6 px track one step up, a 14 px knob. The fill
// is the primary colour (the accent's gradient with Accent › Sliders); a `tint` passed
// in (a load, a battery) keeps its own. Stops are dots in the track. It never
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
  property bool ticks: true              // false: the stops still snap, no marks
  property var spectrum: []              // colours laid along the track, instead of the fill

  // the default tint takes the accent (Appearance › Accent › Sliders); a
  // state colour passed in (a load, a battery) keeps its own
  readonly property bool own: tint !== Theme.foreground0
  readonly property bool accented: !dimmed && !own && Theme.accentOn("sliders")
  readonly property color fill: dimmed ? Theme.gray : own ? tint : Theme.primary
  readonly property bool pressed: area.pressed
  property real dragValue: 0
  // let go: the released position stays shown until the value follows it (an
  // applied change is async: a scale, brightness), or for 2 s if it never does
  property real held: -1
  readonly property real shown: Math.max(0, Math.min(1, pressed ? dragValue : held >= 0 ? held : value))
  onValueChanged: held = -1
  Timer { id: holdTimer; interval: 2000; onTriggered: root.held = -1 }
  function letGo(v) { held = v; holdTimer.restart(); released(v); }
  readonly property real knobSize: Theme.sliderKnob
  readonly property real track: spectrum.length > 0 ? Math.max(Theme.sliderTrack, 6) : Theme.sliderTrack
  readonly property real handleX: shown * (width - knobSize)

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
  implicitHeight: knobSize + 8
  opacity: enabled ? 1 : Theme.disabledOpacity

  Rectangle {
    id: rail
    anchors.verticalCenter: parent.verticalCenter
    width: parent.width
    height: root.track
    radius: Theme.pill(height)
    color: Theme.m3 ? Theme.outlineVariant : Theme.surfaceHigh
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
      width: root.handleX + root.knobSize / 2
      height: parent.height
      radius: parent.radius
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: root.fill }
        GradientStop { position: 1; color: root.accented ? Theme.accentEnd : root.fill }
      }
    }
  }

  // a stop: a dot in the track at that value (at most 11: a long run shows every n-th and the last)
  Repeater {
    model: {
      if (!root.ticks) return [];
      const s = root.snaps, step = Math.ceil((s.length - 1) / 10);
      return step <= 1 ? s : s.filter((v, i) => i % step === 0 || i === s.length - 1);
    }

    Rectangle {
      required property real modelData
      readonly property real cx: modelData * (root.width - root.knobSize) + root.knobSize / 2
      readonly property int size: Math.max(2, root.track - 2)
      x: cx - size / 2
      anchors.verticalCenter: parent.verticalCenter
      width: size
      height: size
      radius: size / 2
      color: cx <= root.handleX + root.knobSize / 2 ? Theme.primaryText : Theme.surfaceVariantText
      opacity: 0.6
    }
  }

  // material: the state layer round the handle
  Rectangle {
    visible: Theme.m3
    anchors.centerIn: knob
    width: 40
    height: 40
    radius: 20
    color: root.fill
    opacity: root.pressed ? Theme.statePressed : area.containsMouse ? Theme.stateHover : 0
    Behavior on opacity { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }
  }

  Rectangle {
    id: knob
    readonly property int size: Theme.strict && (area.containsMouse || root.pressed) ? root.knobSize + 2 : root.knobSize
    width: size
    height: size
    radius: size / 2
    Behavior on width { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }
    Behavior on height { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }
    anchors.verticalCenter: parent.verticalCenter
    x: root.handleX + (root.knobSize - size) / 2
    color: root.spectrum.length > 0 ? Theme.surfaceText : root.fill
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    preventStealing: true
    cursorShape: Qt.PointingHandCursor
    onPressed: mouse => root.send(mouse.x / width)
    onPositionChanged: mouse => { if (pressed) root.send(mouse.x / width); }
    onReleased: root.letGo(root.dragValue)
    onCanceled: root.letGo(root.dragValue)   // a click the page took over still counts
  }
}
