import QtQuick
import qs.config

// Square text field with a dim label above it. The frame brightens on hover and
// while focused. The inner TextInput is exposed as `input` for focus handling.
Item {
  id: root

  property string label: ""
  property string placeholder: ""
  property alias text: input.text
  property alias input: input
  property alias echoMode: input.echoMode

  signal textEdited()
  signal accepted()

  implicitHeight: (caption.visible ? caption.implicitHeight + 4 : 0) + Theme.popupInputHeight

  ThemeText {
    id: caption
    visible: root.label !== ""
    text: root.label
    color: Theme.dim
    font.pixelSize: Theme.fontSize - 2
    font.letterSpacing: 1
  }

  Rectangle {
    anchors {
      left: parent.left; right: parent.right
      top: caption.visible ? caption.bottom : parent.top
      topMargin: caption.visible ? 4 : 0
    }
    height: Theme.popupInputHeight
    color: Theme.background0
    border.width: 1
    border.color: input.activeFocus ? Theme.foreground0 : hover.hovered ? Theme.foreground1 : Theme.muted

    HoverHandler { id: hover }

    TextInput {
      id: input
      anchors.fill: parent
      leftPadding: 6
      rightPadding: 6
      verticalAlignment: TextInput.AlignVCenter
      color: Theme.foreground0
      clip: true
      selectByMouse: true
      activeFocusOnTab: true
      selectionColor: Theme.background2
      selectedTextColor: Theme.foreground0
      font.family: Theme.fontFamily
      font.pixelSize: Theme.fontSize
      font.weight: Theme.fontWeight
      onTextEdited: root.textEdited()
      onAccepted: root.accepted()

      ThemeText {
        anchors { fill: parent; leftMargin: input.leftPadding; rightMargin: input.rightPadding }
        visible: input.text === "" && !input.activeFocus
        text: root.placeholder
        elide: Text.ElideRight
        color: Theme.dim
      }
    }
  }
}
