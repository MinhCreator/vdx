import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar module: CPU load; tinted as it climbs. Opens the system metrics.
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: "cpu"
    // two digits wide, so the bar doesn't shift between 9% and 10%
    text: ModuleSettings.get("sysmon", "barPercent", true) ? String(SysmonService.cpu).padStart(2, " ") + "%" : ""
    tint: Theme.loadColor(SysmonService.cpu)
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "sysmon"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: SysmonService.popupShown()
    onHidden: SysmonService.popupHidden()

    SysmonPopup {
      id: content
      anchors.fill: parent
    }
  }
}
