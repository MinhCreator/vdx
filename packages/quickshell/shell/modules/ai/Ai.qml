import QtQuick
import Quickshell
import qs.bar
import qs.components
import qs.config
import qs.kit

// Robot icon and the percent of the chosen plan limit, Claude's or Codex's
// (Modules › AI › Limit);
// yellow / red when that limit is running out.
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  readonly property string kind: ModuleSettings.get("ai", "limit", "session")
  // a "codex_" kind is Codex's window of that name, the rest Claude's
  readonly property bool codex: kind.startsWith("codex_")
  readonly property var shown: (codex ? CodexService.limits : ClaudeService.limits)
    .find(l => l.kind === (codex ? kind.slice(6) : kind)) ?? null
  readonly property int percent: shown ? shown.percent : -1

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  KitBarItem {
    id: label
    icon: "bot"
    text: BarLayout.faceText("ai", root.percent >= 0 ? root.percent + "%" : "--")
    tint: root.percent >= ClaudeService.critical ? Theme.red
         : root.percent >= ClaudeService.warning ? Theme.yellow
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
