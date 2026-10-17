import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit

// Bell at the right edge. Unseen notifications light it (tint); a tucked-away
// bell tells the Folder (its `attention`), which draws the dot.
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  readonly property bool attention: NotificationsService.unseen > 0

  implicitWidth: bell.implicitWidth
  implicitHeight: bell.implicitHeight

  KitBarItem {
    id: bell
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    icon: "bell"
    tint: root.attention ? Theme.foreground0 : Theme.gray
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
