import QtQuick
import qs.config

// "|" between bar modules.
Item {
  implicitWidth: label.implicitWidth + Theme.separatorMargin * 2
  implicitHeight: label.implicitHeight

  ThemeText {
    id: label
    anchors.centerIn: parent
    text: "|"
    color: Theme.gray
  }
}
