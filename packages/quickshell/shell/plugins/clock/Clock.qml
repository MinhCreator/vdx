import QtQuick
import qs.components
import qs.config

// HH:mm; click switches to the full date.
Item {
  id: root

  property bool full: false
  property date now: new Date()

  // the bar's format, from the Shell Manager's Plugins › Clock
  readonly property string format: (PluginSettings.get("clock", "date", false) ? "ddd dd · " : "")
    + (PluginSettings.get("clock", "twelveHour", false) ? "h:mm" : "HH:mm")
    + (PluginSettings.get("clock", "seconds", false) ? ":ss" : "")
    + (PluginSettings.get("clock", "twelveHour", false) ? " AP" : "")

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText {
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
