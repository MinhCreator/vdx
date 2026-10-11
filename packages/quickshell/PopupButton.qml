import QtQuick

// Small square button for the popup chrome — rofi-style: 1px frame, no radius.
// Renders `label` (uppercase action) or `glyph` (nerd font icon). While `busy`
// the label is swapped for a spinner; a transient `status` ("ok" / "error")
// swaps it for a check or a cross — both in the same square, tinted like the
// rest of the popup.
Item {
  id: root

  property string glyph: ""
  property string label: ""
  property color tint: Theme.dim
  property bool disabled: false
  property bool busy: false
  property string status: ""     // "", "ok", "error"

  readonly property bool clickable: !root.disabled && !root.busy
  readonly property bool hovered: area.containsMouse && root.clickable

  signal clicked()

  // Width follows the label so the button never jumps when it goes busy.
  implicitWidth: root.label !== "" ? labelText.implicitWidth + 14 : 20
  implicitHeight: 20
  // Dim only when it can't be used; a busy button stays crisp so the spinner reads.
  opacity: root.disabled && !root.busy ? 0.4 : 1

  Rectangle {
    anchors.fill: parent
    color: root.hovered ? Theme.background2 : "transparent"
    border.width: 1
    border.color: root.hovered ? root.tint : Theme.frame
  }

  Text {
    id: labelText
    anchors.centerIn: parent
    visible: !root.busy && root.status === ""
    text: root.label !== "" ? root.label : root.glyph
    color: root.tint
    font.family: Theme.fontFamily
    font.pixelSize: root.label !== "" ? Theme.fontSize - 2 : Theme.fontSize - 1
    font.weight: Theme.fontWeight
    font.letterSpacing: root.label !== "" ? 1 : 0
  }

  PopupSpinner {
    anchors.centerIn: parent
    visible: root.busy
    tint: root.tint
  }

  Text {
    anchors.centerIn: parent
    visible: root.status !== ""
    text: root.status === "ok" ? Theme.iconOk : Theme.iconError
    color: root.status === "ok" ? Theme.green : Theme.red
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: { if (root.clickable) root.clicked(); }
  }
}
