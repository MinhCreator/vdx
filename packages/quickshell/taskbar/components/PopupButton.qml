import QtQuick
import qs.config

// Square popup button showing an uppercase `label` or a nerd-font `glyph`.
// `busy` swaps the content for a spinner, `status` ("ok" | "error") for a check
// or a cross. `active` keeps it selected, `frameless` drops the 1px frame and
// `hoverBackground: false` the hover fill.
Item {
  id: root

  property string glyph: ""
  property string label: ""
  property color tint: Theme.dim
  property bool disabled: false
  property bool busy: false
  property string status: ""
  property bool active: false
  property bool frameless: false
  property bool hoverBackground: true
  property int glyphSize: Theme.fontSize - 1

  readonly property bool clickable: !disabled && !busy
  readonly property bool hovered: area.containsMouse && clickable

  signal clicked()

  implicitWidth: label !== "" ? content.implicitWidth + 14 : Math.max(20, glyphSize + 6)
  implicitHeight: label !== "" ? 20 : Math.max(20, glyphSize + 6)
  opacity: disabled && !busy ? 0.4 : 1

  Rectangle {
    anchors.fill: parent
    color: root.active || (root.hoverBackground && root.hovered) ? Theme.background2 : "transparent"
    border.width: root.frameless ? 0 : 1
    border.color: root.active ? Theme.foreground0 : root.hovered ? root.tint : Theme.muted
  }

  ThemeText {
    id: content
    anchors.centerIn: parent
    visible: !root.busy && root.status === ""
    text: root.label !== "" ? root.label : root.glyph
    color: root.tint
    font.pixelSize: root.label !== "" ? Theme.fontSize - 2 : root.glyphSize
    font.letterSpacing: root.label !== "" ? 1 : 0
  }

  PopupSpinner {
    anchors.centerIn: parent
    visible: root.busy
    tint: root.tint
  }

  ThemeText {
    anchors.centerIn: parent
    visible: root.status !== ""
    text: root.status === "ok" ? Theme.iconOk : Theme.iconError
    color: root.status === "ok" ? Theme.green : Theme.red
  }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: if (root.clickable) root.clicked()
  }
}
