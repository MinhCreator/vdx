import QtQuick
import qs.components
import qs.bar
import qs.config
import qs.kit

// Handle, icon and name of a plugin chip in the manager's layout tab.
Item {
  property string pluginId

  anchors.fill: parent

  KitIcon {
    id: grip
    anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
    name: "grip"
    tint: Theme.gray
    size: 16
  }

  KitIcon {
    id: chipIcon
    anchors { left: grip.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
    name: BarLayout.icon(pluginId)
    size: 15
    solid: ShellSettings.solidIcons
  }

  KitText {
    anchors {
      left: chipIcon.right; leftMargin: 6
      right: parent.right; rightMargin: 6
      verticalCenter: parent.verticalCenter
    }
    text: BarLayout.label(pluginId)
    elide: Text.ElideRight
    font.pixelSize: Theme.fontSize - 1
  }
}
