import QtQuick
import qs.bar.island
import qs.config

// The sound as thin bars (EqualizerService.levels): live while it plays, a
// flat dim row when paused. While visible it keeps the service running.
Row {
  id: root

  property color tint: Theme.frame
  property int barWidth: 2

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
      color: root.tint
      opacity: IslandService.playing ? 1 : 0.5
      height: Math.max(width, root.height * (EqualizerService.levels[index] ?? 0))

      Behavior on height { enabled: Motion.bar; NumberAnimation { duration: 70 } }
    }
  }
}
