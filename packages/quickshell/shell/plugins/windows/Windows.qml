import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar module: the window mode's icon (tiling, floating, scrolling); the popup
// switches the mode and places the active window on a part of the screen.
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: (WindowsService.modes.find(m => m.value === WindowsService.mode) ?? WindowsService.modes[0]).icon
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "windows"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    WindowsPopup {
      id: content
      anchors.fill: parent
    }
  }
}
