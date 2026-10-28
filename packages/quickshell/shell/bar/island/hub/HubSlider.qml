import QtQuick
import qs.config
import qs.kit

// A hub slider: a lifted fill up to the value, a white marker at its end, the
// icon and name on the left, the value in mono on the right. Drag or click.
Item {
  id: root

  property string icon: ""
  property string label: ""
  property real value: 0                      // 0..1
  property string text: ""
  property bool enabled: true

  signal moved(real value)

  implicitHeight: 42

  Rectangle {
    id: track
    anchors.fill: parent
    radius: 14
    color: Theme.background2
    clip: true
    opacity: root.enabled ? 1 : 0.5

    Rectangle {
      width: parent.width * root.value
      height: parent.height
      color: Theme.background3
    }
    Rectangle {
      x: Math.max(0, Math.min(track.width - 2, track.width * root.value - 9))
      anchors.verticalCenter: parent.verticalCenter
      width: 2
      height: 16
      radius: 1
      color: Theme.foreground1
    }
    Row {
      anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
      spacing: 10
      KitIcon { name: root.icon; size: 16; tint: Theme.foreground2; anchors.verticalCenter: parent.verticalCenter }
      KitText { text: root.label; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
    }
    KitText {
      anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
      text: root.text
      color: Theme.foreground2
      font.pixelSize: 12
    }
  }

  MouseArea {
    anchors.fill: parent
    enabled: root.enabled
    cursorShape: Qt.PointingHandCursor
    function set(x) { root.moved(Math.max(0, Math.min(1, x / width))); }
    onPressed: mouse => set(mouse.x)
    onPositionChanged: mouse => { if (pressed) set(mouse.x); }
  }
}
