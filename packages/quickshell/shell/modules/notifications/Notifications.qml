import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit

// Bell at the right edge; a red dot while there are unseen notifications.
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  implicitWidth: bell.implicitWidth
  implicitHeight: bell.implicitHeight

  KitBarItem {
    id: bell
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    icon: "bell"
    tint: NotificationsService.unseen > 0 ? Theme.foreground0 : Theme.gray

    // unseen mark: a small red square on the bell's corner
    Rectangle {
      radius: Theme.pill(height)
      visible: NotificationsService.unseen > 0 && ModuleSettings.get("notifications", "dot", true)
      x: Theme.fontSize - 3
      y: 0
      width: 6
      height: 6
      color: Theme.red
      border.width: Theme.frameWidth
      border.color: Theme.background0
    }
  }

  MouseArea {
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
    width: bell.implicitWidth
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: bell
    ipcTarget: "notifications"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: NotificationsService.popupShown()

    NotificationsPopup {
      id: content
      anchors.fill: parent
      onCloseRequested: popup.visible = false
    }
  }
}
