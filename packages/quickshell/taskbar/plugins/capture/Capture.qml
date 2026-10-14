import QtQuick
import Quickshell
import qs.apps.capture
import qs.config
import qs.kit

// Screen capture in the bar: a camera that opens the capture overlay; while
// recording, a red dot with the elapsed time — click to stop.
Item {
  id: root

  required property PanelWindow bar

  property int elapsed: 0

  implicitWidth: face.implicitWidth
  implicitHeight: face.implicitHeight

  KitBarItem {
    id: face
    icon: CaptureService.recording ? "circle" : "camera"
    text: CaptureService.recording
      ? String(Math.floor(root.elapsed / 60)).padStart(2, "0") + ":" + String(root.elapsed % 60).padStart(2, "0")
      : ""
    tint: CaptureService.recording ? Theme.red : Theme.foreground0
  }

  Timer {
    interval: 500
    running: CaptureService.recording
    repeat: true
    triggeredOnStart: true
    onTriggered: root.elapsed = Math.floor((Date.now() - CaptureService.recordStarted) / 1000)
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: CaptureService.open()
  }
}
