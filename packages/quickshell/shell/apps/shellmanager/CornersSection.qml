import QtQuick
import qs.config
import qs.kit

// Appearance › SHAPE (with IconsSection): sharp or round, for
// the whole shell — popups, windows, controls, rows, the island, the icons (the
// Rounded set). Round sets one radius on a ticked slider; smaller things take a
// share of it (Theme). The group's label lives in AppearancePage.
KitColumn {
  id: root

  readonly property var stops: Theme.cornerStops
  readonly property bool round: ShellSettings.corners === "round"
  readonly property var controlStops: [0, 2, 4, 6, 8, 10, 12, 14, 16]

  spacing: Theme.gapGroup

  KitRow {
    wide: true
    label: "Corners"
    hint: "Also windows and toasts; Round rounds the icons"

    KitSegments {
      model: [
        { label: "Sharp", value: "sharp" },
        { label: "Round", value: "round" }
      ]
      current: ShellSettings.corners
      onPicked: value => ShellSettings.set("corners", value)
    }
  }

  // the stops are evenly spaced ticks; a drag snaps from one to the next
  KitSliderRow {
    id: radius
    visible: root.round
    label: "Window radius"
    snaps: root.stops.map((s, i) => i / (root.stops.length - 1))
    value: Math.max(0, root.stops.indexOf(ShellSettings.cornerRadius)) / (root.stops.length - 1)
    text: root.stops[Math.round((radius.pressed ? radius.dragValue : radius.value) * (root.stops.length - 1))] + " px"
    onMoved: value => {
      const px = root.stops[Math.round(value * (root.stops.length - 1))];
      if (px !== ShellSettings.cornerRadius) ShellSettings.set("cornerRadius", px);
    }
  }

  // controls (buttons, fields, switches) take their own radius, 0-16 px
  KitSliderRow {
    id: controlRadius
    visible: root.round
    label: "Controls radius"
    snaps: root.controlStops.map((s, i) => i / (root.controlStops.length - 1))
    value: Math.max(0, root.controlStops.indexOf(ShellSettings.controlRadius)) / (root.controlStops.length - 1)
    text: root.controlStops[Math.round((controlRadius.pressed ? controlRadius.dragValue : controlRadius.value) * (root.controlStops.length - 1))] + " px"
    onMoved: value => {
      const px = root.controlStops[Math.round(value * (root.controlStops.length - 1))];
      if (px !== ShellSettings.controlRadius) ShellSettings.set("controlRadius", px);
    }
  }

  KitGrouper {}
}
