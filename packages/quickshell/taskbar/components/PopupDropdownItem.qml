import QtQuick
import qs.config

// One option of a PopupDropdown: bright label and check mark while `active`.
// `trailing` holds extra right-aligned content (counts, latency, buttons).
Rectangle {
  id: root

  property string label: ""
  property bool active: false

  property alias trailing: trailingRow.data

  signal clicked()

  width: parent ? parent.width : 0
  height: Theme.rowHeight
  color: hover.hovered && root.enabled ? Theme.background2 : "transparent"

  HoverHandler { id: hover }

  ThemeText {
    anchors {
      left: parent.left; leftMargin: 12
      right: trailingRow.left; rightMargin: 8
      verticalCenter: parent.verticalCenter
    }
    text: root.label
    elide: Text.ElideRight
    color: root.active || hover.hovered ? Theme.foreground0 : Theme.foreground2
    font.letterSpacing: 1

    Behavior on color { ColorAnimation { duration: 120 } }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.clicked()
  }

  Row {
    id: trailingRow
    anchors { right: check.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
    spacing: 8
  }

  ThemeText {
    id: check
    anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
    opacity: root.active ? 1 : 0
    text: Theme.iconOk
    color: Theme.green
    font.pixelSize: Theme.fontSize - 1
  }
}
