import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar module: a clipboard icon; opens the history (Super+B, ipc `clipboard`).
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: "clipboard"
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "clipboard"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: ClipboardService.popupShown()

    ClipboardPopup {
      id: content
      anchors.fill: parent
      onPicked: popup.visible = false
    }
  }
}
