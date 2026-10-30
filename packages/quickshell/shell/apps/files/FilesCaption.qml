import QtQuick
import qs.config
import qs.kit

// A caption of the list's table: a click sorts by its column (`key`; "" does not sort), the arrow shows
// the order. The text sits at `textX`, or at the right edge with `alignRight`.
Item {
  id: root

  required property var svc

  property string text: ""
  property string key: ""
  property bool alignRight: false
  property real textX: 0

  readonly property bool sorted: key !== "" && root.svc.sortBy === key

  KitText {
    x: root.alignRight ? root.width - width : root.textX
    anchors.verticalCenter: parent.verticalCenter
    text: root.text + (root.sorted ? (root.svc.sortDesc ? " ↓" : " ↑") : "")
    color: root.sorted || area.containsMouse ? Theme.foreground1 : Theme.muted
    Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.normal; easing.type: Motion.easing } }
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
    font.weight: Font.DemiBold
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: root.key !== ""
    hoverEnabled: true
    cursorShape: root.key !== "" ? Qt.PointingHandCursor : Qt.ArrowCursor
    onClicked: root.svc.sortOn(root.key)
  }
}
