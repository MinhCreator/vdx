import QtQuick
import qs.config
import qs.kit

// A leg of the speed test path between two stops: its latency over a line,
// the caption under it.
Column {
  property real ms: 0                    // 0 = not measured
  property string label: ""
  property string caption: ""

  topPadding: 4
  spacing: 5

  KitText {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: parent.label
    color: Theme.pingColor(parent.ms)
    elide: Text.ElideRight
    font.pixelSize: Theme.fontSize - 1
  }

  KitBar {
    value: parent.ms > 0 ? 1 : 0
    tint: Theme.pingColor(parent.ms)
  }

  KitText {
    width: parent.width
    horizontalAlignment: Text.AlignHCenter
    text: parent.caption
    color: Theme.muted
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }
}
