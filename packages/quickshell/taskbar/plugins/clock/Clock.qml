import QtQuick
import qs.components
import qs.config

// HH:mm; click switches to the full date.
Item {
  id: root

  property bool full: false
  property date now: new Date()

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText {
    id: label
    text: Qt.formatDateTime(root.now, root.full ? "dddd, dd MMMM yyyy HH:mm:ss" : "HH:mm")
    color: Theme.gray
  }

  Timer {
    interval: Theme.clockIntervalMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = new Date()
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: root.full = !root.full
  }
}
