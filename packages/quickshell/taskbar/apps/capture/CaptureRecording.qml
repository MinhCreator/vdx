import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.kit

// While recording: a small panel in the bottom-right corner of the focused
// monitor with the elapsed time and a stop button (Super+Shift+S stops too).
Variants {
  model: CaptureService.recording ? Quickshell.screens.filter(s => s.name === (Hyprland.focusedMonitor?.name ?? s.name)).slice(0, 1) : []

  PanelWindow {
    id: root

    required property var modelData

    property int elapsed: 0

    screen: modelData
    anchors { right: true; bottom: true }
    margins { right: 16; bottom: 16 }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-recording"
    implicitWidth: panel.implicitWidth
    implicitHeight: panel.implicitHeight
    color: "transparent"

    Timer {
      interval: 500
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: root.elapsed = Math.floor((Date.now() - CaptureService.recordStarted) / 1000)
    }

    Rectangle {
      id: panel
      implicitWidth: row.implicitWidth + 20
      implicitHeight: row.implicitHeight + 16
      color: Theme.background0
      border.width: Theme.frameWidth
      border.color: Theme.frame

      Row {
        id: row
        x: 10
        y: 8
        spacing: 10

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          width: 10
          height: 10
          color: Theme.red
          opacity: root.elapsed % 2 === 0 ? 1 : 0.35
        }

        KitText {
          anchors.verticalCenter: parent.verticalCenter
          text: "REC " + String(Math.floor(root.elapsed / 60)).padStart(2, "0") + ":" + String(root.elapsed % 60).padStart(2, "0")
          font.weight: Font.ExtraBold
        }

        KitButton {
          icon: "square"
          text: "Stop"
          onClicked: CaptureService.stopRecording()
        }
      }
    }
  }
}
