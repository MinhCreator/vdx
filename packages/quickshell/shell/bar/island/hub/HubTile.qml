import QtQuick
import qs.config
import qs.kit

// One tile of the hub: a mono caption with a state dot, the value, a detail
// line. On = a lifted surface and a glowing dot in the state colour; off = the
// block surface, dim text. A click is the tile's own action.
Rectangle {
  id: root

  property string title: ""
  property string value: ""
  property string detail: ""
  property bool on: false
  property color tone: Theme.green
  property alias extra: extraSlot.data

  signal clicked()

  implicitHeight: 104
  radius: 20
  color: on ? Theme.background3 : Theme.background1

  Item {
    anchors { fill: parent; margins: 14 }

    KitText {
      text: root.title
      color: root.on ? Theme.foreground2 : Theme.dim
      font.pixelSize: 11
      font.letterSpacing: 0.9
    }
    Rectangle {
      anchors { right: parent.right; top: parent.top; topMargin: 3 }
      width: 6
      height: 6
      radius: 3
      color: root.on ? root.tone : Theme.gray
    }

    Column {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
      spacing: 4

      KitText {
        width: parent.width
        text: root.value
        color: root.on ? Theme.foreground0 : Theme.dim
        font.pixelSize: 17
        font.weight: Font.Medium
        elide: Text.ElideRight
      }
      Row {
        spacing: 6
        height: 14
        Item { id: extraSlot; width: childrenRect.width; height: parent.height }
        KitText {
          anchors.verticalCenter: parent.verticalCenter
          width: Math.min(implicitWidth, root.width - 28 - extraSlot.width - 6)
          elide: Text.ElideRight
          visible: text !== ""
          text: root.detail
          color: root.on ? Theme.muted : Theme.dim
          font.pixelSize: 11
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }
}
