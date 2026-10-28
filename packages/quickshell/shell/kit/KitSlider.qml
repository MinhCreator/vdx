import QtQuick
import qs.config

// Strict: a bar filled up to the value with a white marker at its end, the
// name inside on the left and the reading on the right (`barLabel`, `barValue`),
// the stops as dots; a spectrum keeps the thin track. Thin slider: a 3px track, the filled part in `tint`, a round knob; with
// Appearance › Controls › Material it is Material 3's: a thick track split by a
// bar handle, stops as dots inside the track. It never
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
  property string barLabel: ""           // Strict bar: the name inside, left
  property string barValue: ""           // Strict bar: the reading inside, right
  property real barHeight: 42

  // the default tint takes the accent (Appearance › Accent › Sliders); a
  // state colour passed in (a load, a battery) keeps its own
  readonly property bool accented: !dimmed && tint === Theme.foreground0 && Theme.accentOn("sliders")
  readonly property color fill: dimmed ? Theme.gray : accented ? Theme.accent : tint
  readonly property bool pressed: area.pressed
  property real dragValue: 0
  // let go: the released position stays shown until the value follows it (an
  // applied change is async: a scale, brightness), or for 2 s if it never does
  property real held: -1
  readonly property real shown: Math.max(0, Math.min(1, pressed ? dragValue : held >= 0 ? held : value))
  onValueChanged: held = -1
  Timer { id: holdTimer; interval: 2000; onTriggered: root.held = -1 }
  function letGo(v) { held = v; holdTimer.restart(); released(v); }
  readonly property real knobSize: m3 ? 4 : 12
  readonly property bool m3: Theme.material && spectrum.length === 0
  readonly property bool bar: !Theme.material && spectrum.length === 0    // the Strict bar
  readonly property real track: 12            // Material: the track's height
  readonly property real gap: 5               // Material: the space on each side of the handle
  readonly property real handleX: shown * (width - knobSize)

  property string accessibleName: "Level"
  property real keyboardStep: 0.05
  activeFocusOnTab: true
  Accessible.role: Accessible.Slider
  Accessible.name: accessibleName
  Accessible.description: Math.round(shown * 100) + "%"
  function adjust(step) {
    if (!enabled || dimmed) return;
    let next;
    if (snaps.length) {
      const choices = snaps.filter(s => step > 0 ? s > shown + 0.001 : s < shown - 0.001);
      next = choices.length ? (step > 0 ? choices[0] : choices[choices.length - 1]) : shown;
    } else next = Math.max(0, Math.min(1, shown + step * keyboardStep));
    send(next);
    letGo(next);
  }
  Keys.onLeftPressed: adjust(-1)
  Keys.onRightPressed: adjust(1)
  Accessible.onIncreaseAction: adjust(1)
  Accessible.onDecreaseAction: adjust(-1)

  Rectangle {
    anchors { fill: parent; margins: -3 }
    radius: Theme.radiusControl
    visible: root.activeFocus
    color: Theme.clear
    border.width: Theme.focusWidth
    border.color: Theme.focusRing
  }

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
  implicitHeight: bar ? barHeight : m3 ? 28 : 18
  opacity: enabled ? 1 : 0.4

  Rectangle {
    visible: !root.m3 && !root.bar
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
    id: stops
    // at most 11 marks: a long run of stops shows every n-th (and the last); it still snaps to each
    model: {
      if (!root.ticks) return [];
      const s = root.snaps, step = Math.ceil((s.length - 1) / 10);
      return step <= 1 ? s : s.filter((v, i) => i % step === 0 || i === s.length - 1);
    }

    Rectangle {
      required property real modelData
      visible: !root.m3 && !root.bar
      x: modelData * (root.width - root.knobSize) + root.knobSize / 2 - 1
      anchors.verticalCenter: parent.verticalCenter
      width: 2
      height: 10
      radius: Theme.pill(width)
      color: Theme.gray
    }
  }

  // ---- Material 3: active track | gap | handle | gap | inactive track ----
  Rectangle {
    visible: root.m3
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(0, root.handleX - root.gap)
    height: root.track
    radius: Theme.pill(height)
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0; color: root.fill }
      GradientStop { position: 1; color: root.accented ? Theme.accentEnd : root.fill }
    }
  }

  Rectangle {
    visible: root.m3
    anchors.verticalCenter: parent.verticalCenter
    x: Math.min(root.width, root.handleX + root.knobSize + root.gap)
    width: Math.max(0, root.width - x)
    height: root.track
    radius: Theme.pill(height)
    color: Theme.background3
  }

  // stops: a dot per shown stop (none under the handle), and one at the end
  Repeater {
    model: !root.m3 ? [] : root.ticks && root.snaps.length > 0 ? stops.model : [1]

    Rectangle {
      required property real modelData
      readonly property real cx: modelData * (root.width - root.knobSize) + root.knobSize / 2
      visible: Math.abs(cx - (root.handleX + root.knobSize / 2)) > root.gap + 3 && cx > 4 && cx < root.width - 4 || modelData === 1 && root.shown < 0.97
      x: Math.max(3, Math.min(root.width - 7, cx - 2))
      anchors.verticalCenter: parent.verticalCenter
      width: 4
      height: 4
      radius: 2
      color: cx < root.handleX ? Theme.background0 : root.fill
      opacity: 0.8
    }
  }

  Rectangle {
    visible: root.m3
    anchors.verticalCenter: parent.verticalCenter
    x: root.handleX
    width: root.knobSize
    height: area.containsMouse || root.pressed ? root.track + 16 : root.track + 12
    radius: Theme.pill(width)
    color: root.fill
    Behavior on height { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }
  }

  Rectangle {
    visible: !root.m3 && !root.bar
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

  // ---- Strict bar: the track, the fill, the stops, the marker, the texts ----
  Rectangle {
    id: bar
    visible: root.bar
    anchors.fill: parent
    radius: Theme.radiusControl
    color: Theme.background1
    clip: true

    Rectangle {
      width: root.shown * parent.width
      height: parent.height
      color: root.accented || root.tint !== Theme.foreground0 ? Qt.rgba(root.fill.r, root.fill.g, root.fill.b, 0.3) : Theme.background3
    }

    // the stops, a dot each (none under the marker)
    Repeater {
      model: root.bar && root.ticks ? stops.model : []

      Rectangle {
        required property real modelData
        readonly property real cx: modelData * bar.width
        visible: Math.abs(cx - root.shown * bar.width) > 14 && cx > 8 && cx < bar.width - 8
        x: cx - 2
        anchors.verticalCenter: parent.verticalCenter
        width: 4
        height: 4
        radius: Theme.pill(width)
        color: Theme.gray
      }
    }

    Rectangle {
      x: Math.max(4, Math.min(bar.width - 6, root.shown * bar.width - 9))
      anchors.verticalCenter: parent.verticalCenter
      width: 2
      height: 16
      radius: 1
      color: root.dimmed ? Theme.gray : Theme.foreground1
    }

    KitText {
      anchors { left: parent.left; leftMargin: Theme.gapWide + 2; verticalCenter: parent.verticalCenter }
      text: root.barLabel
      color: root.dimmed ? Theme.gray : Theme.foreground0
    }
    KitText {
      anchors { right: parent.right; rightMargin: Theme.gapWide + 2; verticalCenter: parent.verticalCenter }
      text: root.barValue
      color: root.dimmed ? Theme.gray : Theme.foreground2
    }
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
