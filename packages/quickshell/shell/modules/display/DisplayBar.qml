import QtQuick
import Quickshell
import qs.apps.display
import qs.bar
import qs.config
import qs.kit

// Bar module: the GTK text size; the popup sets each monitor's scale and the
// text size, and its button opens the full window (arrangement lives there).
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: "monitor"
    text: DisplayService.monitors.length > 0 ? Math.round(DisplayService.textFactor * 100) + "%" : "--"
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "monitors"
    moduleId: "display"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: DisplayService.refresh()

    DisplayPopup {
      id: content
      anchors.fill: parent
      onOpenWindow: popup.visible = false
    }
  }
}
