import QtQuick

// Square text field for the popup chrome — rofi-style: 1px frame, no radius.
// A dim UPPERCASE label sits above the field; the frame uses `muted` at rest,
// brightens to `foreground1` on hover and `foreground0` while the field holds
// keyboard focus. Typing happens in the inner TextInput, exposed as `input` so
// the owner can hand it focus (and read `activeFocus`); the label/placeholder
// live here.
Item {
  id: root

  property string label: ""
  property string placeholder: ""
  property alias text: input.text
  property alias input: input

  readonly property bool hovered: fieldHover.hovered

  signal textEdited()
  signal accepted()

  implicitHeight: labelText.implicitHeight + 4 + Theme.popupInputHeight

  Text {
    id: labelText
    text: root.label
    color: Theme.dim
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize - 3
    font.weight: Theme.fontWeight
    font.letterSpacing: 1
  }

  Rectangle {
    id: field
    anchors {
      left: parent.left
      right: parent.right
      top: labelText.bottom
      topMargin: 4
    }
    height: Theme.popupInputHeight
    color: Theme.background0
    border.width: 1
    border.color: input.activeFocus ? Theme.foreground0
                : root.hovered ? Theme.foreground1
                : Theme.muted

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

      // placeholder — hidden once the field is focused or holds text
      Text {
        anchors.fill: parent
        anchors.leftMargin: input.leftPadding
        anchors.rightMargin: input.rightPadding
        verticalAlignment: Text.AlignVCenter
        visible: input.text === "" && !input.activeFocus
        text: root.placeholder
        elide: Text.ElideRight
        color: Theme.dim
        font: input.font
      }
    }

    HoverHandler {
      id: fieldHover
    }
  }
}
