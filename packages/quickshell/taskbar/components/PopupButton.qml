import QtQuick
import qs.components
import qs.config

// Small square button for the popup chrome — rofi-style: 1px frame, no radius.
// Renders `label` (uppercase action), `glyph` (nerd font icon) or `icon`
// (tinted svg — see components/Icon.qml). While `busy` the label is swapped
// for a spinner; a transient `status` ("ok" / "error") swaps it for a check or
// a cross — both in the same square, tinted like the rest of the popup.
// `active` is a persistent "selected" state (DNS pills); `frameless` drops
// the frame and keeps only the hover tint (header buttons); `glyphSize` lets
// an icon/glyph-only button grow its icon (and its own hit area).
Item {
  id: root

  property string glyph: ""
  property url icon: ""
  property string label: ""
  property color tint: Theme.dim
  property bool disabled: false
  property bool busy: false
  property string status: ""
  property bool active: false
  property bool frameless: false
  property int glyphSize: Theme.fontSize - 1

  readonly property bool clickable: !root.disabled && !root.busy
  readonly property bool hovered: area.containsMouse && root.clickable

  signal clicked()

  implicitWidth: root.label !== ""
               ? labelText.implicitWidth + 14
               : Math.max(20, root.glyphSize + 6)
  implicitHeight: root.label !== ""
                ? 20
                : Math.max(20, root.glyphSize + 6)
  opacity: root.disabled && !root.busy ? 0.4 : 1

  Rectangle {
    anchors.fill: parent
    color: (root.active || root.hovered) ? Theme.background2 : "transparent"
    border.width: root.frameless ? 0 : 1
    border.color: root.active ? Theme.foreground0
                : root.hovered ? root.tint
                : Theme.muted
  }

  Text {
    id: labelText
    anchors.centerIn: parent
    visible: !root.busy && root.status === "" && root.icon === ""
    text: root.label !== "" ? root.label : root.glyph
    color: root.tint
    font.family: Theme.fontFamily
    font.pixelSize: root.label !== "" ? Theme.fontSize - 2 : root.glyphSize
    font.weight: Theme.fontWeight
    font.letterSpacing: root.label !== "" ? 1 : 0
  }

  Icon {
    anchors.centerIn: parent
    visible: !root.busy && root.status === "" && root.icon !== ""
    source: root.icon
    color: root.tint
    size: root.glyphSize
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
