import QtQuick
import qs.config

// Collapsible list under a full-width header: chevron, title, an optional hint
// (short warning, `hintColor`) and a busy / ok / error mark on the right. Options are PopupDropdownItems placed as children;
// the list scrolls past `maxListHeight`. The owner collapses the dropdown when
// an option is picked.
Item {
  id: root

  property string title: ""
  property bool expanded: false
  property bool disabled: false
  property bool busy: false
  property string status: ""            // "" | ok | error
  property string hint: ""
  property color hintColor: Theme.orange

  property real maxListHeight: Theme.rowHeight * Theme.visibleRows

  default property alias options: list.data

  // Framed like PopupButton / PopupInput: muted at rest, lighter on hover,
  // full foreground while open; the open list shares the header's frame.
  readonly property color frameColor: root.expanded ? Theme.foreground0
                                    : area.containsMouse && !root.disabled ? Theme.foreground1
                                    : Theme.muted

  implicitHeight: header.height + Math.max(0, box.height - 1)

  onDisabledChanged: if (disabled) expanded = false

  Rectangle {
    id: header
    width: parent.width
    height: 28
    color: area.containsMouse || root.expanded ? Theme.background2 : "transparent"
    border.width: 1
    border.color: root.frameColor

    Behavior on border.color { ColorAnimation { duration: 120 } }

    ThemeText {
      id: chevron
      anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
      text: Theme.iconChevron
      color: root.disabled ? Theme.muted : root.expanded || area.containsMouse ? Theme.foreground0 : Theme.foreground1
      font.pixelSize: Theme.fontSize - 3
      rotation: root.expanded ? 90 : 0

      Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 120 } }
    }

    ThemeText {
      anchors {
        left: chevron.right; leftMargin: 6
        right: hintText.visible ? hintText.left : mark.left; rightMargin: 6
        verticalCenter: parent.verticalCenter
      }
      text: root.title
      color: root.disabled ? Theme.muted : Theme.foreground0
      elide: Text.ElideRight
      font.letterSpacing: 1
    }

    ThemeText {
      id: hintText
      anchors { right: mark.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
      visible: root.hint !== ""
      text: root.hint
      color: root.hintColor
      font.pixelSize: Theme.fontSize - 2
    }

    Item {
      id: mark
      anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
      width: 14
      height: 14

      PopupSpinner {
        anchors.centerIn: parent
        visible: root.busy
        tint: Theme.foreground0
      }

      ThemeText {
        anchors.centerIn: parent
        visible: root.status !== ""
        text: root.status === "ok" ? Theme.iconOk : Theme.iconError
        color: root.status === "ok" ? Theme.green : Theme.red
        font.pixelSize: Theme.fontSize + 1
      }
    }

    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      enabled: !root.disabled && !root.busy
      cursorShape: Qt.PointingHandCursor
      onClicked: root.expanded = !root.expanded
    }
  }

  Rectangle {
    id: box
    y: header.height - 1
    width: parent.width
    height: root.expanded ? Math.min(list.implicitHeight, root.maxListHeight) + 8 : 0
    visible: height > 0
    clip: true
    color: Theme.frame
    border.width: 1
    border.color: root.frameColor

    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Flickable {
      anchors { fill: parent; margins: 1; topMargin: 4; bottomMargin: 4 }
      contentHeight: list.implicitHeight
      interactive: contentHeight > height
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: list
        width: parent.width
      }
    }
  }
}
