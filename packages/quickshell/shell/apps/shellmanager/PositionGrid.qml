import QtQuick
import qs.config

// A tiny screen map: its 3 × 3 cells pick the window's anchor point.
Item {
  id: root

  property string current: ""
  readonly property var spots: ["top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"]

  signal picked(string spot)

  implicitWidth: 108
  implicitHeight: 56

  Rectangle {
    anchors.fill: parent
    radius: Theme.radiusControl
    color: Theme.background1
    border.width: Theme.frameWidth
    border.color: Theme.controlLineRest
  }

  Grid {
    id: cells
    anchors.centerIn: parent
    columns: 3
    spacing: 4

    Repeater {
      model: root.spots

      Rectangle {
        radius: Theme.radiusControl
        id: cell

        required property string modelData

        readonly property bool active: modelData === root.current

        width: 27
        height: 11
        color: active ? Theme.pickFill : area.containsMouse ? Theme.background3 : Theme.background0
        Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick; easing.type: Motion.easing } }
        border.width: active ? Theme.focusWidth : Theme.frameWidth
        border.color: active ? Theme.focusRing : area.containsMouse ? Theme.controlLineHover : Theme.controlLineRest

        MouseArea {
          id: area
          anchors.fill: parent
          anchors.margins: -1
          hoverEnabled: true
          cursorShape: cell.active ? Qt.ArrowCursor : Qt.PointingHandCursor
          Accessible.role: Accessible.Button
          Accessible.name: cell.modelData.replace("-", " ")
          Accessible.onPressAction: if (!cell.active) root.picked(cell.modelData)
          onClicked: if (!cell.active) root.picked(cell.modelData)
        }
      }
    }
  }
}
