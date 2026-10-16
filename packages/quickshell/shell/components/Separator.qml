import QtQuick
import qs.config
import qs.kit

// "|" between bar modules.
Item {
  implicitWidth: label.implicitWidth + Theme.separatorMargin * 2
  implicitHeight: label.implicitHeight

  KitText {
    id: label
    anchors.centerIn: parent
    text: "|"
    color: Theme.gray
  }
}
