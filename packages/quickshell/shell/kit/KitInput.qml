import QtQuick
import qs.config

// A text field. The inner TextInput is exposed as `input` for focus handling;
// `passKeys` go to keyPassed (list arrows).
// `search` (on by default for a placeholder starting "Search"): the search bar — a
// full-rounded bar with a search icon (Material 48 px in surfaceContainerHigh,
// Strict 40 px one step up). Otherwise a field: Material the M3 text field, 56 px,
// Filled (a container, square lower corners, an active indicator) or Outlined (a
// 1 px outline, 2 px primary while focused), with an optional floating `label`;
// Strict a 40 px full-rounded field, filled or framed. Outlined: no fill.
Rectangle {
  id: root

  property string placeholder: ""
  property string label: ""                 // material: the floating label
  property bool search: placeholder.indexOf("Search") === 0
  property alias text: textInput.text
  property alias input: textInput
  property alias echoMode: textInput.echoMode
  // a masked field stands in the middle by default (lock screen, Wi-Fi); a prompt that
  // reads like a line (polkit) turns it off and the squares start at the left
  property bool centerMasked: true

  // keys the field hands on instead of using (a list's arrows): keyPassed(key)
  property var passKeys: []

  signal textEdited()
  signal accepted()
  signal keyPassed(int key)

  readonly property bool focused: textInput.activeFocus
  readonly property bool hovered: hover.hovered
  readonly property bool m3Field: Theme.m3 && !search
  readonly property bool floated: m3Field && label !== "" && (focused || textInput.text !== "")
  readonly property color base: search ? (Theme.filled ? (Theme.m3 ? Theme.surfaceHigh : Theme.surfaceContainer) : Theme.clear)
                                       : Theme.fieldFill

  width: parent ? parent.width : 0
  implicitHeight: search ? Theme.searchHeight : Theme.fieldHeight
  radius: m3Field ? Theme.radiusField : Theme.radiusFor(implicitHeight)
  // set once: whether it sits in a Settings box (a walk up, not a binding)
  property bool boxed: false
  Component.onCompleted: boxed = Theme.boxed(parent)
  color: hovered && !focused ? Theme.hover(base) : base
  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }
  border.width: Theme.filled ? 0 : m3Field && focused ? 2 : 1
  border.color: focused ? (Theme.m3 ? Theme.primary : Theme.outlineActive)
              : hovered ? Theme.outlineActive : Theme.outline
  Behavior on border.color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  KitFieldLine { visible: root.m3Field && Theme.filled; active: root.focused }

  HoverHandler { id: hover; cursorShape: Qt.IBeamCursor }

  KitIcon {
    id: lead
    anchors { left: parent.left; leftMargin: Theme.gapWide + (Theme.m3 ? 4 : 0); verticalCenter: parent.verticalCenter }
    visible: root.search
    name: "search"
    size: Theme.iconControl
    tint: Theme.surfaceVariantText
  }

  // material: the floating label, small at the top once the field holds focus or text
  KitText {
    visible: root.m3Field && root.label !== ""
    x: Theme.gapWide + 4
    y: root.floated ? Theme.gapMedium : (root.height - height) / 2
    text: root.label
    color: root.focused ? Theme.primary : Theme.surfaceVariantText
    font.pixelSize: root.floated ? Theme.fontSize - 2 : Theme.textField
    Behavior on y { enabled: Motion.controls; NumberAnimation { duration: Motion.quick; easing.type: Motion.easing } }
  }

  TextInput {
    id: textInput
    // a password stands in the middle of the field
    readonly property bool masked: echoMode === TextInput.Password
    readonly property bool centred: masked && root.centerMasked
    readonly property int side: Theme.gapWide + (Theme.m3 ? 4 : 0)
    anchors {
      left: root.search ? lead.right : parent.left
      leftMargin: root.search ? Theme.gapMedium : side
      right: parent.right
      rightMargin: side
      top: parent.top
      topMargin: root.m3Field && root.label !== "" ? Theme.gapLoose + 6 : 0
      bottom: parent.bottom
    }
    verticalAlignment: TextInput.AlignVCenter
    horizontalAlignment: centred ? TextInput.AlignHCenter : TextInput.AlignLeft
    leftPadding: centred ? font.letterSpacing : 0   // the spacing trails every square, the last one too
    color: Theme.surfaceText
    clip: true
    selectByMouse: true
    activeFocusOnTab: true
    selectionColor: Theme.selectedFill
    selectedTextColor: Theme.selectedText
    font.family: Theme.fontFamily
    font.pixelSize: Theme.textField
    font.weight: Font.Normal
    // a password: squares (or dots, Appearance) with air between them (lock screen, root prompt)
    passwordCharacter: ShellSettings.passwordDots ? "•" : "■"
    font.letterSpacing: masked ? 4 : 0
    onTextEdited: root.textEdited()
    onAccepted: root.accepted()
    Keys.onPressed: event => {
      if (!root.passKeys.includes(event.key)) return;
      event.accepted = true;
      root.keyPassed(event.key);
    }

    cursorDelegate: Rectangle {
      width: 2
      color: Theme.m3 ? Theme.primary : Theme.surfaceText
      visible: textInput.activeFocus

      SequentialAnimation on opacity {
        running: textInput.activeFocus
        loops: Animation.Infinite
        NumberAnimation { to: 1; duration: 0 }
        PauseAnimation { duration: 530 }
        NumberAnimation { to: 0; duration: 0 }
        PauseAnimation { duration: 530 }
      }
    }

    KitText {
      anchors.fill: parent
      visible: textInput.text === "" && (!(root.m3Field && root.label !== "") || root.floated)
      text: root.placeholder !== "" || root.m3Field ? root.placeholder : root.label
      elide: Text.ElideRight
      color: Theme.surfaceVariantText
      font.pixelSize: Theme.textField
      font.weight: Font.Normal
    }
  }
}
