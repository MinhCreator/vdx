import QtQuick
import qs.config
import "colour.js" as Colour

// A colour in one box: a chip (click it for the picker), the hex (typed), and a
// chevron that opens the picker too. Typed text is handed over as `edited`; a
// valid hex is `accepted` at once when `live`, or on Enter. Left invalid, the
// field goes back to its last valid colour. The field follows `value` while it
// is not typed in.
Rectangle {
  id: root

  property string value: ""
  property string placeholder: "#32302f"
  property bool live: false
  property bool open: false
  property bool showPickerButton: true
  property bool dirty: false
  property bool invalid: false
  readonly property bool typedValid: Colour.normalize(input.text) !== ""
  readonly property bool valid: Colour.normalize(value) !== ""
  readonly property string colour: Colour.normalize(value)
  property string saved: colour      // the last valid colour

  signal edited(string text)
  signal accepted(string colour)
  signal chipClicked()

  implicitHeight: Theme.controlHeight
  radius: Theme.radiusControl
  // set once: whether it sits in a Settings box (a walk up, not a binding)
  property bool boxed: false
  color: input.activeFocus || hover.hovered ? Theme.hoverOn(boxed) : Theme.fillOn(boxed)
  border.width: input.activeFocus && !Theme.material ? Theme.focusWidth : Theme.frameWidth
  border.color: invalid ? Theme.red : input.activeFocus ? Theme.focusRing : hover.hovered ? Theme.controlLineHover : Theme.controlLine
  Behavior on border.color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  KitFieldLine { active: input.activeFocus }

  HoverHandler { id: hover; cursorShape: Qt.IBeamCursor }

  onValueChanged: {
    if (!input.activeFocus || !dirty) { input.text = value; invalid = false; }
    if (valid) saved = colour;
  }
  Component.onCompleted: { boxed = Theme.boxed(parent); input.text = value; }

  Rectangle {
    id: chip
    anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
    width: Theme.controlHeight - 12
    height: width
    activeFocusOnTab: root.showPickerButton
    Accessible.role: Accessible.Button
    Accessible.name: "Choose colour"
    Accessible.onPressAction: root.chipClicked()
    Keys.onSpacePressed: root.chipClicked()
    Keys.onReturnPressed: root.chipClicked()
    radius: Theme.radiusControl
    color: root.valid ? root.colour : "transparent"
    border.width: Theme.frameWidth
    border.color: activeFocus ? Theme.focusRing : Theme.controlLine

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      enabled: root.showPickerButton
      onClicked: root.chipClicked()
    }
  }

  TextInput {
    id: input
    anchors { left: chip.right; leftMargin: Theme.gapMedium; right: root.showPickerButton ? chevron.left : parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
    color: Theme.foreground0
    clip: true
    selectByMouse: true
    activeFocusOnTab: true
    Accessible.name: "Hex colour"
    selectionColor: Theme.background3
    selectedTextColor: Theme.foreground0
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight

    Text {
      visible: input.text === "" && !input.activeFocus
      text: root.placeholder
      color: Theme.muted
      font: input.font
    }

    function commit() {
      root.invalid = !root.typedValid;
      if (root.invalid) return;
      root.saved = Colour.normalize(text);
      root.dirty = false;
      text = root.saved;
      root.accepted(root.saved);
    }
    onTextEdited: {
      root.dirty = true;
      root.invalid = false;
      root.edited(text);
      // Shorthand is expanded only on commit, never midway through six digits.
      if (root.live && /^#?[0-9a-fA-F]{6}$/.test(text.trim())) commit();
    }
    onAccepted: commit()
    Keys.onEscapePressed: {
      text = root.colour || root.saved;
      root.dirty = false;
      root.invalid = false;
      root.edited(text);
    }
    onActiveFocusChanged: {
      if (!activeFocus && root.dirty) commit();
    }

  }

  KitIcon {
    id: chevron
    visible: root.showPickerButton
    anchors { right: parent.right; rightMargin: Theme.gapMedium; verticalCenter: parent.verticalCenter }
    name: "chevron-down"
    tint: Theme.foreground2
    size: Theme.iconSmall
    rotation: root.open ? 180 : 0

    Behavior on rotation { enabled: Motion.controls; NumberAnimation { duration: Motion.normal; easing.type: Motion.easing } }

    MouseArea {
      anchors.fill: parent
      anchors.margins: -Theme.gapMedium
      cursorShape: Qt.PointingHandCursor
      onClicked: root.chipClicked()
    }
  }
}
