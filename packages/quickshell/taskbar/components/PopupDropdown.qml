import QtQuick
import qs.config

// Collapsible list under a full-width header: chevron, title and a busy / ok /
// error mark on the right. Options are PopupDropdownItems placed as children;
// the list scrolls past `maxListHeight`. The owner collapses the dropdown when
// an option is picked.
Item {
  id: root

  property string title: ""
  property bool expanded: false
  property bool disabled: false
  property bool busy: false
  property string status: ""            // "" | ok | error

  property real maxListHeight: Theme.rowHeight * Theme.visibleRows

  default property alias options: list.data

  implicitHeight: header.height + box.height

  onDisabledChanged: if (disabled) expanded = false

  Rectangle {
    id: header
    width: parent.width
    height: 28
    color: area.containsMouse || root.expanded ? Theme.background2 : "transparent"

    ThemeText {
      id: chevron
      anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
      text: Theme.iconChevron
      color: root.disabled ? Theme.muted : root.expanded ? Theme.foreground0 : Theme.dim
      font.pixelSize: Theme.fontSize - 3
      rotation: root.expanded ? 90 : 0

      Behavior on rotation { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
      Behavior on color { ColorAnimation { duration: 120 } }
    }

    ThemeText {
      anchors {
        left: chevron.right; leftMargin: 6
        right: mark.left; rightMargin: 6
        verticalCenter: parent.verticalCenter
      }
      text: root.title
      color: root.disabled ? Theme.muted : Theme.foreground0
      elide: Text.ElideRight
      font.letterSpacing: 1
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
    y: header.height
    width: parent.width
    height: root.expanded ? Math.min(list.implicitHeight, root.maxListHeight) + 8 : 0
    clip: true
    color: Theme.frame
    border.width: 1
    border.color: Theme.background2

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
