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
  property int barCount: EqualizerService.bars      // fewer bars take their levels evenly from the 12
  property bool active: IslandService.playing    // live bars, else a dim flat row
  property var tone: null                       // one colour for all, over the module's own

  // the colour of bar i: the gradient's step at its place
  function colourAt(i) {
    if (tone) return tone;
    const [a, b] = colours;
    const t = barCount > 1 ? i / (barCount - 1) : 0;
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
    model: root.barCount

    Rectangle {
      required property int index

      anchors.verticalCenter: parent.verticalCenter
      width: root.barWidth
      radius: Theme.pill(width)
      color: root.colourAt(index)
      opacity: root.active ? 1 : 0.5
      height: Math.max(width, root.height * (EqualizerService.levels[Math.floor((index + 0.5) * EqualizerService.bars / root.barCount)] ?? 0))

      Behavior on height { enabled: Motion.bar; NumberAnimation { duration: Motion.ms(70) } }
    }
  }
}
