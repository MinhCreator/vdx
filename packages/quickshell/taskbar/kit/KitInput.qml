import QtQuick
import qs.config

// Outlined text field as a prompt: "❯", the text, a blinking block cursor. The
// frame brightens on hover and while focused. The inner TextInput is exposed
// as `input` for focus handling.
Rectangle {
  id: root

  property string placeholder: ""
  property alias text: input.text
  property alias input: input
  property alias echoMode: input.echoMode

  signal textEdited()
  signal accepted()

  width: parent ? parent.width : 0
  implicitHeight: 32
  color: "transparent"
  border.width: Theme.frameWidth
  border.color: input.activeFocus || hover.hovered ? Theme.foreground2 : Theme.gray

  HoverHandler { id: hover; cursorShape: Qt.IBeamCursor }

  KitText {
    id: prompt
    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
    text: "❯"
    color: input.activeFocus ? Theme.yellow : Theme.gray
  }

  TextInput {
    id: input
    anchors { left: prompt.right; leftMargin: 8; right: parent.right; rightMargin: 10; top: parent.top; bottom: parent.bottom }
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.foreground0
    clip: true
    selectByMouse: true
    activeFocusOnTab: true
    selectionColor: Theme.background3
    selectedTextColor: Theme.foreground0
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Font.DemiBold
    onTextEdited: root.textEdited()
    onAccepted: root.accepted()

    cursorDelegate: Rectangle {
      width: Math.round(Theme.fontSize * 0.6)
      color: Theme.foreground0
      visible: input.activeFocus

      SequentialAnimation on opacity {
        running: input.activeFocus
        loops: Animation.Infinite
        NumberAnimation { to: 0.8; duration: 0 }
        PauseAnimation { duration: 530 }
        NumberAnimation { to: 0; duration: 0 }
        PauseAnimation { duration: 530 }
      }
    }

    KitText {
      anchors.fill: parent
      visible: input.text === "" && !input.activeFocus
      text: root.placeholder
      elide: Text.ElideRight
      color: Theme.gray
    }
  }
}
