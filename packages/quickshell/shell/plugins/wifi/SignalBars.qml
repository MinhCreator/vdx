import QtQuick
import qs.config

// Four ascending bars for a 0..100 signal strength.
Row {
  id: root

  property int strength: 0

  readonly property int level: strength >= 75 ? 4 : strength >= 50 ? 3 : strength >= 25 ? 2 : strength > 0 ? 1 : 0
  readonly property color tint: strength > 0 ? Theme.qualityColor(strength, 60, 30) : Theme.muted

  spacing: 2

  Repeater {
    model: 4

    Rectangle {
      required property int index

      anchors.bottom: parent.bottom
      width: 3
      height: 3 * (index + 1)
      color: root.tint
      opacity: index < root.level ? 1 : 0.25
    }
  }
}
