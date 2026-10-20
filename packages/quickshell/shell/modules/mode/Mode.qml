import QtQuick
import qs.apps.shellmanager
import qs.bar
import qs.config
import qs.kit

// Bar module: light or dark. A click switches the theme to its twin
// (ThemeService.setLight); no popup. The face shows a sun or a moon, and the
// mode's name under Bar text › Content (Modules › Mode).
Item {
  id: root

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: ThemeService.light ? "sun" : "moon"
    text: BarLayout.faceText("mode", ThemeService.light ? "Light" : "Dark")
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: ThemeService.busy ? Qt.BusyCursor : Qt.PointingHandCursor
    onClicked: if (!ThemeService.busy) ThemeService.setLight(!ThemeService.light)
  }
}
