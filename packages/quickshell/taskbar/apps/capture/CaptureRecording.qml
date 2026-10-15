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
    implicitWidth: Theme.popupWidth
    implicitHeight: panel.implicitHeight
    color: "transparent"

    Timer {
      interval: 500
      running: true
      repeat: true
      triggeredOnStart: true
      onTriggered: root.elapsed = Math.floor((Date.now() - CaptureService.recordStarted) / 1000)
    }

    // the popups' frame: a header with the time and Stop, then where it goes
    KitFrame {
      id: panel

      anchors.fill: parent

      KitHeader {
        icon: "circle"
        iconColor: Theme.red
        title: "Recording"
        subtitle: String(Math.floor(root.elapsed / 60)).padStart(2, "0") + ":" + String(root.elapsed % 60).padStart(2, "0")
          + " · " + CaptureService.fps + " FPS" + (CaptureService.audio !== "off" ? " · " + CaptureService.audio.toUpperCase() : "")

        KitButton {
          icon: "square"
          text: "Stop"
          onClicked: CaptureService.stopRecording()
        }
      }

      KitLine {}

      KitInfo {
        label: "Saves to"
        value: CaptureService.recordAsk ? "asks when you stop" : CaptureService.recordFile.replace(CaptureService.videoDir.split("/").slice(0, 3).join("/"), "~")
      }
    }
  }
}
