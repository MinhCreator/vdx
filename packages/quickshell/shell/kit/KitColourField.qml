import QtQuick
import qs.config

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
  readonly property bool valid: /^#?[0-9a-fA-F]{6}$/.test(value.trim())
  readonly property string colour: valid ? "#" + value.trim().replace(/^#/, "").toLowerCase() : ""
  property string saved: colour      // the last valid colour

  signal edited(string text)
  signal accepted(string colour)
  signal chipClicked()

  implicitHeight: 32
  radius: Theme.radiusControl
  color: input.activeFocus || hover.hovered ? Theme.controlHover : Theme.controlFill
  border.width: Theme.frameWidth
  border.color: input.activeFocus || hover.hovered ? Theme.foreground2 : Theme.gray
  Behavior on border.color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  HoverHandler { id: hover; cursorShape: Qt.IBeamCursor }

  onValueChanged: {
    if (!input.activeFocus) input.text = value;
    if (valid) saved = colour;
  }
  Component.onCompleted: input.text = value

  Rectangle {
    id: chip
    anchors { left: parent.left; leftMargin: 5; verticalCenter: parent.verticalCenter }
    width: 18
    height: 18
    radius: Theme.radiusControl
    color: root.valid ? root.colour : "transparent"
    border.width: Theme.frameWidth
    border.color: Theme.gray

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.chipClicked()
    }
  }

  TextInput {
    id: input
    anchors { left: chip.right; leftMargin: Theme.gapMedium; right: chevron.left; rightMargin: Theme.gapSmall; verticalCenter: parent.verticalCenter }
    color: Theme.foreground0
    clip: true
    selectByMouse: true
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

    onTextEdited: {
      root.edited(text);
      const t = text.trim();
      if (root.live && /^#?[0-9a-fA-F]{6}$/.test(t)) {
        root.saved = "#" + t.replace(/^#/, "").toLowerCase();
        root.accepted(root.saved);
      }
    }
    onAccepted: if (root.valid) { root.saved = root.colour; root.accepted(root.colour); }
    onActiveFocusChanged: {
      if (activeFocus || root.valid || root.saved === "") return;
      input.text = root.saved;
      root.edited(root.saved);
    }
  }

  KitIcon {
    id: chevron
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
