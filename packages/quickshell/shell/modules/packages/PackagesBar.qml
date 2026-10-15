import QtQuick
import Quickshell
import qs.apps.packages
import qs.bar
import qs.config
import qs.kit

// Bar module: the number of pending updates (repos and AUR), yellow while
// there are some; the popup updates or rolls back the last upgrade, and the
// full window (Shell Manager › Shell apps) has the installed packages and the cache.
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: "download"
    text: !PackagesService.opt("showCount", true) ? ""
        : PackagesService.checkedAt === 0 ? "--" : String(PackagesService.count)
    tint: PackagesService.count > 0 && PackagesService.opt("tint", true) ? Theme.yellow : Theme.foreground0
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "updates"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: PackagesService.freshen()

    PackagesPopup {
      id: content
      anchors.fill: parent
      onOpenWindow: popup.visible = false
    }
  }
}
