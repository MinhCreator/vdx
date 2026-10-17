import QtQuick
import qs.config
import qs.kit

// The display settings: the arrangement of the monitors (drag or arrow keys),
// the selected monitor's scale (a slider whose stops are the scales it offers),
// refresh rate and position, and the GTK text size. Choices apply at once; a
// failure shows under the groups.
KitFrame {
  id: root

  framed: false
  padding: Theme.windowPadding
  headerInset: Theme.headerInset
  bottomInset: Theme.textDescent

  readonly property var ds: DisplayService
  readonly property var sizes: ds.textScales.map(f => ({ label: pct(f), value: f }))
  // the monitor the arrangement and the MONITOR group are about
  property string selected: ""
  readonly property var current: ds.monitors.find(m => m.name === selected) ?? ds.monitors[0] ?? null

  function pct(f) { return Math.round(f * 100) + "%"; }


  KitHeader {
    icon: "monitor"
    title: "Display"
    subtitle: ds.monitors.length + (ds.monitors.length === 1 ? " MONITOR" : " MONITORS")
              + " · TEXT " + root.pct(ds.textFactor)
  }

  KitLine {}

  KitLabel { text: "ARRANGE"; value: "DRAG OR ARROWS" }

  MonitorLayout {
    width: parent.width
    height: 170
    selected: root.current ? root.current.name : ""
    onPicked: name => root.selected = name
  }

  KitLine {}

  KitLabel { text: "MONITOR"; value: root.current ? root.current.name : "" }

  KitSliderRow {
    id: scaleSlider
    visible: root.current !== null
    enabled: !ds.busy
    label: "Scale"
    snaps: root.current ? ds.stops(root.current) : []
    value: root.current ? ds.scalePos(root.current) : 0
    text: root.current ? root.pct(ds.stopAt(root.current, scaleSlider.pressed ? scaleSlider.dragValue : scaleSlider.value)) : ""
    onReleased: value => ds.setScale(root.current.name, ds.stopAt(root.current, value))
  }

  KitSelect {
    visible: root.current !== null
    overlay: true
    disabled: ds.busy
    label: "Refresh rate"
    hint: root.current ? root.current.width + "x" + root.current.height : ""
    model: root.current ? root.current.refreshes.map(r => ({ label: r + " Hz", value: r })) : []
    current: root.current ? root.current.refresh : null
    busy: root.current !== null && ds.working === "rate:" + root.current.name
    onPicked: value => ds.setRate(root.current.name, value)
  }

  KitRow {
    visible: root.current !== null
    label: "Position"
    hint: "Logical pixels, from the top left"

    KitText {
      text: root.current ? root.current.x + ", " + root.current.y : ""
      color: Theme.muted
    }
  }

  KitLine {}

  KitLabel { text: "TEXT SIZE"; value: root.pct(ds.textFactor) }

  KitRow {
    wide: true
    label: "GTK apps"
    hint: "All monitors · GTK only"

    KitChoices {
      stretch: true
      disabled: ds.busy
      model: root.sizes
      current: ds.textFactor
      busyValue: ds.working === "text" ? ds.pending : null
      onPicked: value => ds.setText(value)
    }
  }

  KitText {
    visible: ds.error !== ""
    width: parent.width
    text: ds.error
    color: Theme.red
    wrapMode: Text.WordWrap
  }
}
