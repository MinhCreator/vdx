import QtQuick
import Quickshell
import qs.bar
import qs.config
import qs.kit

// Bar module: a folder for modules tucked off the bar (Shell Manager › Bar,
// FOLDER row); the count next to it. Its popup lists them as tiles; a tile
// opens that module's own popup. The modules themselves live here, clipped to
// the folder's size and out of sight, so their popups open where the folder's does.
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

    // the folder's own size, clipped and under its click area: nothing shows,
    // and their popups line up exactly with the folder's
    Loader {
      required property string modelData
      clip: true
      width: root.width
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
