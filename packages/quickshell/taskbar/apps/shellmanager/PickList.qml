import QtQuick
import qs.config
import qs.kit

// A framed, scrolling list like the theme list: the highlighted row is
// `selected`, the one in use carries a check, the one being worked on a
// spinner, and a row that still has to be downloaded a download mark.
// Rows: [{ key, label, installed, family? }] — `family` draws the label in
// that font.
Rectangle {
  id: root

  property var model: []
  property string selected: ""
  property string current: ""
  property string working: ""

  signal picked(var row)

  color: "transparent"
  border.width: Theme.frameWidth
  border.color: Theme.gray

  WheelGuard { flick: list; z: 1 }

  Flickable {
    id: list
    anchors { fill: parent; margins: Theme.frameWidth }
    contentHeight: rows.implicitHeight
    interactive: contentHeight > height
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Column {
      id: rows
      width: parent.width

      Repeater {
        model: root.model

        Rectangle {
          id: row

          required property var modelData

          readonly property bool active: modelData.key === root.selected

          width: rows.width
          height: 32
          color: active ? Theme.background3 : rowArea.containsMouse ? Theme.background1 : "transparent"

          KitText {
            anchors {
              left: parent.left; leftMargin: 10
              right: mark.left; rightMargin: 6
              verticalCenter: parent.verticalCenter
            }
            text: row.modelData.label
            elide: Text.ElideRight
            color: !row.modelData.installed ? Theme.muted
                 : row.active || rowArea.containsMouse ? Theme.foreground0 : Theme.foreground2
            font.weight: row.active ? Font.ExtraBold : Font.DemiBold
            font.family: row.modelData.family && row.modelData.installed ? row.modelData.family : Theme.fontFamily
          }

          Item {
            id: mark
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            width: 14
            height: 14

            KitSpinner {
              anchors.centerIn: parent
              visible: root.working === row.modelData.key
            }

            KitIcon {
              anchors.centerIn: parent
              visible: root.working !== row.modelData.key
                       && (row.modelData.key === root.current || !row.modelData.installed)
              name: row.modelData.key === root.current ? "check" : "download"
              tint: row.modelData.key === root.current ? Theme.green : Theme.muted
              size: 14
            }
          }

          MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: row.active ? Qt.ArrowCursor : Qt.PointingHandCursor
            onClicked: root.picked(row.modelData)
          }
        }
      }
    }
  }
}
