import QtQuick
import Quickshell
import qs.apps.shellmanager
import qs.bar
import qs.config
import qs.kit

// Bar module: the dotfiles theme. Click opens a strip of theme cards to
// switch from, or a list (ThemesPopup); the wheel steps to the next /
// previous theme (Modules › Themes).
Item {
  id: root

  required property PanelWindow bar

  // the Folder opens this module's popup when its tile is clicked
  function openPopup() { popup.toggle(); }

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: "palette"
    text: BarLayout.faceText("themes", ModuleSettings.get("themes", "name", true) ? ThemeService.current : "")
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
    onWheel: wheel => {
      const list = ThemeService.themes;
      if (!ModuleSettings.get("themes", "barWheel", true) || ThemeService.busy || list.length === 0
          || wheel.angleDelta.y === 0) return;
      const i = list.indexOf(ThemeService.current);
      ThemeService.apply(list[(i + (wheel.angleDelta.y > 0 ? -1 : 1) + list.length) % list.length]);
    }
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "themes"
    moduleId: "themes"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: content.shown()

    ThemesPopup {
      id: content
      anchors.fill: parent
    }
  }
}
