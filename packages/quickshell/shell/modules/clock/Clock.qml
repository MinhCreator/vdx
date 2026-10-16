import QtQuick
import qs.config
import qs.kit

// HH:mm; click switches to the full date.
Item {
  id: root

  property bool full: false
  property date now: new Date()

  // the bar's format, from the Shell Manager's Modules › Clock
  readonly property string format: (ModuleSettings.get("clock", "date", false) ? "ddd dd · " : "")
    + (ModuleSettings.get("clock", "twelveHour", false) ? "h:mm" : "HH:mm")
    + (ModuleSettings.get("clock", "seconds", false) ? ":ss" : "")
    + (ModuleSettings.get("clock", "twelveHour", false) ? " AP" : "")

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  KitText {
    id: label
    text: Qt.formatDateTime(root.now, root.full ? "dddd, dd MMMM yyyy HH:mm:ss" : root.format)
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
