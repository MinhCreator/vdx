import QtQuick
import qs.config
import qs.kit

// Appearance › STYLE (with IconsSection and ControlsSection): sharp or round, for
// the whole shell — popups, windows, controls, rows, the island, the icons (the
// Rounded set). Round sets one radius on a ticked slider; smaller things take a
// share of it (Theme). The group's label lives in AppearancePage.
KitColumn {
  id: root

  readonly property var stops: Theme.cornerStops
  readonly property bool round: ShellSettings.corners === "round"

  spacing: Theme.gapGroup

  KitRow {
    wide: true
    label: "Corners"
    hint: "Icons included"

    KitChoices {
      stretch: true
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
    label: "Radius"
    snaps: root.stops.map((s, i) => i / (root.stops.length - 1))
    value: Math.max(0, root.stops.indexOf(ShellSettings.cornerRadius)) / (root.stops.length - 1)
    text: root.stops[Math.round((radius.pressed ? radius.dragValue : radius.value) * (root.stops.length - 1))] + " px"
    onMoved: value => {
      const px = root.stops[Math.round(value * (root.stops.length - 1))];
      if (px !== ShellSettings.cornerRadius) ShellSettings.set("cornerRadius", px);
    }
  }
}
