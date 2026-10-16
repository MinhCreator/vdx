import QtQuick
import Quickshell
import qs.apps.virustotal
import qs.bar
import qs.config
import qs.kit

// Bar module: the scanner's icon; the popup looks a hash, URL or file up,
// and the full window (Shell Manager › Shell apps) keeps the details.
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: "scan"
    tint: !VirusTotalService.opt("tint", true) ? Theme.foreground0
        : VirusTotalService.verdict === "malicious" ? Theme.red
        : VirusTotalService.verdict === "suspicious" ? Theme.yellow : Theme.foreground0
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "scan"
    moduleId: "virustotal"
    onShown: if (VirusTotalService.clipboardOn) VirusTotalService.readClipboard(content)
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    VirusTotalPopup {
      id: content
      anchors.fill: parent
      onOpenWindow: popup.visible = false
    }
  }
}
