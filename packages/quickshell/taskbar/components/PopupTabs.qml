import QtQuick
import qs.config

// Text tabs over a hairline: the active one is bright and underlined, the
// others dim (brighter on hover). Model: [{label, value}].
Item {
  id: root

  property var model: []
  property var current: null

  signal picked(var value)

  implicitHeight: 28

  Rectangle {
    anchors.bottom: parent.bottom
    width: parent.width
    height: 1
    color: Theme.background2
  }

  Row {
    anchors.fill: parent

    Repeater {
      model: root.model

      Item {
        id: tab

        required property var modelData

        readonly property bool active: modelData.value === root.current

        width: root.width / root.model.length
        height: root.height

        ThemeText {
          anchors.centerIn: parent
          text: tab.modelData.label
          color: tab.active ? Theme.foreground0 : area.containsMouse ? Theme.foreground2 : Theme.dim
          font.letterSpacing: 1
        }

        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          height: 2
          color: Theme.foreground0
          visible: tab.active
        }

        MouseArea {
          id: area
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: tab.active ? Qt.ArrowCursor : Qt.PointingHandCursor
          onClicked: if (!tab.active) root.picked(tab.modelData.value)
        }
      }
    }
  }
}
