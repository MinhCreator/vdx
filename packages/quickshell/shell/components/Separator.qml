import QtQuick
import qs.config
import qs.kit

// "|" between bar modules. Without the line (`ruled` false, Bar › Style ›
// Separators off) its room stays: the modules keep their distance.
Item {
  property bool ruled: true

  implicitWidth: label.implicitWidth + Theme.separatorMargin * 2
  implicitHeight: label.implicitHeight

  KitText {
    id: label
    visible: parent.ruled
    anchors.centerIn: parent
    text: "|"
    color: Theme.gray
  }
}
