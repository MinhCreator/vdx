import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config

// Robot icon; yellow / red when a plan limit is running out.
Item {
  id: root

  required property PanelWindow bar

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText {
    id: label
    text: Theme.iconRobot
    color: ClaudeService.peak >= Theme.claudeCritical ? Theme.red
         : ClaudeService.peak >= Theme.claudeWarning ? Theme.yellow
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
