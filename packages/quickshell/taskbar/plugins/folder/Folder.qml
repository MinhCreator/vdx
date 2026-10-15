import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar module: a folder for modules tucked off the bar (Shell Manager › Bar,
// FOLDER row); the count next to it. Its popup lists them as tiles; a tile
// opens that module's own popup. The modules themselves live here, zero-wide
// and out of sight, so their popups open under the folder.
Item {
  id: root

  required property PanelWindow bar
  property var modules: ({})          // Bar's plugin id -> Component

  readonly property var ids: BarLayout.inFolder(bar.screen?.name ?? "")

  function moduleItem(id) {
    for (let i = 0; i < tucked.count; i++)
      if (tucked.itemAt(i)?.modelData === id) return tucked.itemAt(i).item;
    return null;
  }

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: "folder"
    text: root.ids.length > 0 ? String(root.ids.length) : ""
    tint: root.ids.length > 0 ? Theme.foreground0 : Theme.gray
  }

  Repeater {
    id: tucked
    model: root.ids

    // zero-wide and clipped: nothing shows, their popups still open
    Loader {
      required property string modelData
      clip: true
      width: 0
      height: root.height
      sourceComponent: root.modules[modelData] ?? null
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "folder"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    FolderPopup {
      id: content
      anchors.fill: parent
      ids: root.ids
      onPicked: id => {
        popup.visible = false;
        Qt.callLater(() => root.moduleItem(id)?.openPopup?.());
      }
    }
  }
}
