import QtQuick
import qs.config
import qs.kit

// A folder as a tile above the files (Settings › Folders as tiles): its icon, name and items; a click
// selects, a double click opens, ⋮ or a right click opens its menu. Files dropped on it go in.
Rectangle {
  id: root

  required property var files     // the Files window
  required property var entry

  readonly property bool picked: files.svc.selection.includes(entry.path)
  readonly property bool hovered: area.containsMouse || more.containsMouse

  height: 40
  radius: Theme.radiusControl
  color: picked ? Theme.background3 : hovered ? Theme.background2 : Theme.background1
  border.width: dropArea.containsDrag ? 2 : 0
  border.color: Theme.foreground2
  Behavior on color { enabled: Motion.controls; ColorAnimation { duration: Motion.quick } }

  MouseArea {
    id: area
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: mouse => {
      if (mouse.button === Qt.RightButton) root.files.contextMenu(root.entry, mapToItem(null, mouse.x, mouse.y));
      else root.files.click(root.entry, mouse);
    }
    onDoubleClicked: mouse => { if (mouse.button === Qt.LeftButton) root.files.open(root.entry); }
  }

  KitIcon {
    id: icon
    anchors { left: parent.left; leftMargin: Theme.gapLoose; verticalCenter: parent.verticalCenter }
    name: "folder"
    size: Theme.iconSmall + 2
    tint: root.entry.link ? Theme.muted : Theme.foreground0
  }

  Column {
    anchors { left: icon.right; leftMargin: Theme.gapMedium; right: dots.left; rightMargin: Theme.gapHair; verticalCenter: parent.verticalCenter }

    KitText {
      width: parent.width
      text: root.entry.name + (root.entry.link ? " →" : "")
      elide: Text.ElideRight
      font.weight: root.picked ? Font.ExtraBold : Theme.fontWeight
    }

    KitText {
      width: parent.width
      visible: root.entry.count !== undefined
      text: root.entry.count < 0 ? "no access" : root.entry.count === 1 ? "1 item" : root.entry.count + " items"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
    }
  }

  // ⋮: the folder's menu
  Rectangle {
    id: dots
    anchors { right: parent.right; rightMargin: Theme.gapHair; verticalCenter: parent.verticalCenter }
    width: 26
    height: 26
    radius: Theme.radiusFor(height)
    visible: files.svc.rowActions
    opacity: root.hovered || root.picked ? 1 : 0
    color: more.containsMouse ? Theme.hoverOn(true) : Theme.clear
    Behavior on opacity { enabled: Motion.controls; NumberAnimation { duration: Motion.quick } }

    KitIcon { anchors.centerIn: parent; name: "more"; size: Theme.iconSmall + 2; tint: Theme.foreground2 }

    MouseArea {
      id: more
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: mouse => root.files.contextMenu(root.entry, mapToItem(null, mouse.x, mouse.y))
    }
  }

  // files dropped on a tile are copied into that folder
  DropArea {
    id: dropArea
    anchors.fill: parent
    keys: ["text/uri-list"]
    onDropped: drop => root.files.dropped(drop.urls ?? [], root.entry.path)
  }
}
