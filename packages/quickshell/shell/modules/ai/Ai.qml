import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit

// Robot icon; yellow / red when a plan limit is running out.
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  KitBarItem {
    id: label
    icon: "bot"
    tint: ClaudeService.peak >= ClaudeService.critical ? Theme.red
         : ClaudeService.peak >= ClaudeService.warning ? Theme.yellow
         : Theme.foreground0
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "ai"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: ClaudeService.popupShown()
    onHidden: ClaudeService.popupHidden()

    AiPopup {
      id: content
      anchors.fill: parent
    }
  }
}
