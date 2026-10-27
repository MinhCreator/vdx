import QtQuick
import qs.config
import qs.kit

// Bar dividers use the same stroke as panels; hiding a stroke preserves the
// user's chosen module spacing.
Item {
  property bool ruled: true
  implicitWidth: Theme.dividerThickness + Theme.separatorMargin * 2
  implicitHeight: Theme.iconSmall
  KitLine {
    vertical: true
    visible: parent.ruled
    anchors.centerIn: parent
    height: Theme.iconSmall
  }
}
