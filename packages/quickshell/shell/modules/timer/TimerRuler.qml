import QtQuick
import qs.config
import qs.kit

// A ruler of minutes: a tick each, filled up to `value`, a label every ten.
// Drag or click to set it, the wheel steps by one.
Item {
  id: root

  property int value: 15
  property int from: 1
  property int to: 60
  property color tint: Theme.orange
  signal moved(int value)

  readonly property int ticks: to + 1
  readonly property real step: width / ticks

  implicitHeight: 44

  function setAt(x) {
    const v = Math.max(from, Math.min(to, Math.round(x / step - 0.5)));
    if (v !== value) moved(v);
  }

  Repeater {
    model: root.ticks
    Rectangle {
      required property int index
      readonly property bool major: index % 10 === 0
      x: index * root.step + (root.step - width) / 2
      y: major ? 14 : 18
      width: 2
      height: root.height - y
      radius: width / 2
      color: index <= root.value && index >= root.from ? root.tint : Theme.background3
      Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
    }
  }
  Repeater {
    model: Math.floor(root.to / 10) + 1
    KitText {
      required property int index
      x: index * 10 * root.step + root.step / 2 - width / 2
      y: 0
      text: String(index * 10)
      color: index * 10 <= root.value ? root.tint : Theme.muted
      font.pixelSize: Theme.fontSize - 3
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onPressed: mouse => root.setAt(mouse.x)
    onPositionChanged: mouse => { if (pressed) root.setAt(mouse.x); }
    onWheel: w => {
      const v = Math.max(root.from, Math.min(root.to, root.value + (w.angleDelta.y > 0 ? 1 : -1)));
      if (v !== root.value) root.moved(v);
    }
  }
}
