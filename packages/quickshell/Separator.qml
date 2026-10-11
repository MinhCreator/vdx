import QtQuick
import Quickshell

// custom/separator: "|", margin 8px each side, color gray (separator.css)

Item {
  Text {
    id: label
    anchors.centerIn: parent
    text: "|"
    color: Theme.gray
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: label.implicitWidth + Theme.separatorMargin * 2
  implicitHeight: label.implicitHeight
}