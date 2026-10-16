import QtQuick
import qs.config
import qs.kit

// The display settings: the arrangement of the monitors (drag or arrow keys),
// the selected monitor's scale and position, and the GTK text size. Choices
// apply at once; a failure shows under the groups.
Rectangle {
  id: root

  color: Theme.background0
  implicitHeight: column.implicitHeight + 27   // 16 px around the drawn content: 3 px of it sit inside the header's box

  readonly property var ds: DisplayService
  readonly property var sizes: ds.textScales.map(f => ({ label: pct(f), value: f }))
  // the monitor the arrangement and the MONITOR group are about
  property string selected: ""
  readonly property var current: ds.monitors.find(m => m.name === selected) ?? ds.monitors[0] ?? null

  function pct(f) { return Math.round(f * 100) + "%"; }

  Column {
    id: column
    x: 16
    y: 13
    width: parent.width - 32
    spacing: 14

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

    KitRow {
      visible: root.current !== null
      wide: true
      label: "Scale"
      hint: root.current ? root.current.width + "x" + root.current.height + " · " + root.current.refresh + " Hz" : ""

      KitChoices {
        stretch: true
        disabled: ds.busy
        model: root.current ? root.current.scales.map(s => ({ label: root.pct(s), value: s })) : []
        current: root.current ? root.current.scale : null
        busyValue: root.current && ds.working === "scale:" + root.current.name ? ds.pending : null
        onPicked: value => ds.setScale(root.current.name, value)
      }
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
}
