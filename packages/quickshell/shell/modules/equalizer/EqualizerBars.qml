import QtQuick
import qs.bar.island
import qs.config

// The sound as thin bars (EqualizerService.levels): live while it plays, a
// flat dim row when paused. While visible it keeps the service running. The
// colour is Modules › Equalizer's: one, or a gradient from the left bar to the right.
Row {
  id: root

  readonly property var colours: Theme.equalizerColours(ModuleSettings.get("equalizer", "colour", "theme"))
  property int barWidth: 2

  // the colour of bar i: the gradient's step at its place
  function colourAt(i) {
    const [a, b] = colours;
    const t = EqualizerService.bars > 1 ? i / (EqualizerService.bars - 1) : 0;
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
  }

  spacing: 2

  // `visible` is the effective one: hidden with any parent
  property bool counted: false
  function count() {
    if (visible === counted) return;
    counted = visible;
    EqualizerService.users += visible ? 1 : -1;
  }
  onVisibleChanged: count()
  Component.onCompleted: count()
  Component.onDestruction: if (counted) EqualizerService.users--

  Repeater {
    model: EqualizerService.bars

    Rectangle {
      required property int index

      anchors.verticalCenter: parent.verticalCenter
      width: root.barWidth
      radius: Theme.pill(width)
      color: root.colourAt(index)
      opacity: IslandService.playing ? 1 : 0.5
      height: Math.max(width, root.height * (EqualizerService.levels[index] ?? 0))

      Behavior on height { enabled: Motion.bar; NumberAnimation { duration: Motion.ms(70) } }
    }
  }
}
