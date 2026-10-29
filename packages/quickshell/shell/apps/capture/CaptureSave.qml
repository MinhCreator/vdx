import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

// Save as: when a capture is set to ask (Shell Manager › Apps › Capture, or
// the panel), a small window on the focused monitor offers the suggested path
// to edit. Enter saves there; Esc keeps a shot on the clipboard only and puts
// a recording in its default folder.
Variants {
  model: CaptureService.pending ? Quickshell.screens.filter(s => s.name === (Hyprland.focusedMonitor?.name ?? s.name)).slice(0, 1) : []

  PanelWindow {
    required property var modelData

    screen: modelData
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-capture-save"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight
    color: "transparent"

    CaptureSavePanel {
      id: frame
      anchors.fill: parent
      controller: CaptureService
      home: Quickshell.env("HOME")
    }
  }
}
