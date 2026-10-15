import QtQuick
import Quickshell
import qs.apps.clipboard
import qs.bar
import qs.config
import qs.kit

// Bar module: the clipboard's icon; the popup is the history itself (click to
// copy back, × to delete), and the full window opens from the app (Shell apps).
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
    ipcTarget: "clip"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: ClipboardService.refresh()

    Clipboard {
      id: content
      anchors.fill: parent
      maxRows: ModuleSettings.get("clipboard", "rows", 0)
      search: ModuleSettings.get("clipboard", "search", true)
      onPicked: if (ModuleSettings.get("clipboard", "closeOnCopy", true)) popup.visible = false
    }
  }
}
