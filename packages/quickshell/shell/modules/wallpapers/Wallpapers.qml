import QtQuick
import Quickshell
import qs.apps.shellmanager
import qs.bar
import qs.config
import qs.kit

// Bar module: the picture of the active theme. Click opens a strip of cards
// (or a list, WallpapersPopup) to pick from; the wheel steps to the next /
// previous picture (Modules › Wallpapers).
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  readonly property string current: WallpaperService.inUse.split("/").pop()

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: "image"
    text: BarLayout.faceText("wallpapers", ModuleSettings.get("wallpapers", "name", false) ? (root.current || "--") : "")
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
    onWheel: wheel => {
      const list = WallpaperService.pictures;
      if (!ModuleSettings.get("wallpapers", "barWheel", true) || list.length === 0
          || wheel.angleDelta.y === 0) return;
      const i = list.findIndex(p => p.rel === WallpaperService.inUse);
      const step = wheel.angleDelta.y > 0 ? -1 : 1;
      WallpaperService.choose(ThemeService.current, list[(Math.max(i, 0) + step + list.length) % list.length].rel);
    }
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "wallpapers"
    moduleId: "wallpapers"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: content.shown()

    WallpapersPopup {
      id: content
      anchors.fill: parent
      live: popup.visible
    }
  }
}
