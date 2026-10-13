import QtQuick
import qs.config

// clock (gruvbox): format {:%H:%M}, alt {:%A, %d %B %Y %H:%M:%S},
// on-click "mode", refresh 1s, color gray (clock.css)

Item {
  id: root

  property bool showAlt: false
  property date now: new Date()

  // waybar uses the process locale for strftime; the environment is en_US.UTF-8,
  // so pin the month/day names to en_US for a 1:1 alt format.
  readonly property string pretty: root.showAlt
      ? Qt.formatDateTime(root.now, "dddd, dd MMMM yyyy HH:mm:ss")
      : Qt.formatDateTime(root.now, "HH:mm")

  Text {
    id: label
    text: root.pretty
    color: Theme.gray
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Timer {
    interval: Theme.clockIntervalMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor // waybar: HAND2 when the module has events
    onClicked: root.showAlt = !root.showAlt // waybar on-click "mode"
  }
}