import QtQuick
import qs.components
import qs.config

// Handle, icon and name of a plugin chip in the manager's layout tab.
Item {
  property string pluginId

  anchors.fill: parent

  ThemeText {
    id: grip
    anchors { left: parent.left; leftMargin: 6; verticalCenter: parent.verticalCenter }
    text: Theme.iconDrag
    color: Theme.foreground2
    font.pixelSize: Theme.fontSize + 2
  }

  ThemeText {
    id: chipIcon
    anchors { left: grip.right; leftMargin: 6; verticalCenter: parent.verticalCenter }
    text: Theme[BarLayout.icon(pluginId)] ?? ""
  }

  ThemeText {
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
