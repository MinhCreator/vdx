import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config

// Bell at the right edge; a red dot while there are unseen notifications.
Item {
  id: root

  required property PanelWindow bar

  implicitWidth: bell.implicitWidth
  implicitHeight: bell.implicitHeight

  ThemeText {
    id: bell
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    text: Theme.iconBell
    color: NotificationsService.unseen > 0 ? Theme.foreground0 : Theme.gray

    Rectangle {
      visible: NotificationsService.unseen > 0
      anchors { right: parent.right; top: parent.top; rightMargin: -1; topMargin: 2 }
      width: 6
      height: 6
      radius: 3
      color: Theme.red
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
    }
  }
}
