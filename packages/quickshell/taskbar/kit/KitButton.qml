import QtQuick
import qs.config

// Outlined button: an optional icon and a label. `selected` fills it in the
// raised tone with a lighter frame and bold text (one of a group of choices).
// `busy` swaps the icon for a spinner.
Rectangle {
  id: root

  property string icon: ""               // kit/icons name; wins over glyph
  property string glyph: ""
  property string text: ""
  property bool selected: false
  property bool busy: false
  property bool disabled: false

  readonly property bool hovered: area.containsMouse && !disabled

  signal clicked()

  implicitWidth: content.implicitWidth + (text !== "" ? 24 : 14)
  implicitHeight: 30
  color: selected ? Theme.background3 : hovered ? Theme.background1 : "transparent"
  border.width: 1
  border.color: selected || hovered ? Theme.foreground2 : Theme.gray
  opacity: disabled ? 0.4 : 1

  Row {
    id: content
    anchors.centerIn: parent
    spacing: 8

    KitIcon {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.icon !== "" && !root.busy
      name: root.icon
      size: Theme.fontSize + 1
    }

    KitText {
      visible: root.icon === "" && root.glyph !== "" && !root.busy
      text: root.glyph
      font.pixelSize: Theme.fontSize + 1
    }

    KitSpinner {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.busy
    }

    KitText {
      visible: root.text !== ""
      text: root.text
      font.weight: root.selected ? Font.Bold : Font.Medium
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    onClicked: if (!root.disabled && !root.busy) root.clicked()
  }
}
