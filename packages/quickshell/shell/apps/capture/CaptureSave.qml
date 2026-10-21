import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.kit

// Save as: when a capture is set to ask (Shell Manager › Apps › Capture, or
// the panel), a small window on the focused monitor offers the suggested path
// to edit. Enter saves there; Esc keeps a shot on the clipboard only and puts
// a recording in its default folder.
Variants {
  model: CaptureService.pending ? Quickshell.screens.filter(s => s.name === (Hyprland.focusedMonitor?.name ?? s.name)).slice(0, 1) : []

  PanelWindow {
    id: root

    required property var modelData

    readonly property bool video: CaptureService.pending?.kind === "video"

    screen: modelData
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-capture-save"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    implicitWidth: frame.implicitWidth
    implicitHeight: frame.implicitHeight
    color: "transparent"

    KitFrame {
      id: frame
      implicitWidth: 480
      anchors.fill: parent

      Keys.onEscapePressed: CaptureService.dismissSave()

      KitHeader {
        icon: root.video ? "video" : "camera"
        title: root.video ? "Save recording" : "Save screenshot"
        subtitle: root.video ? "esc · save to the default folder" : "esc · keep it on the clipboard only"
      }

      KitLine {}

      KitInput {
        id: path
        width: parent.width
        // ~ for the home folder; confirmSave expands it back
        text: (CaptureService.pending?.path ?? "").replace(Quickshell.env("HOME"), "~")
        placeholder: "path"
        onAccepted: CaptureService.confirmSave(text)
        Component.onCompleted: { input.forceActiveFocus(); input.cursorPosition = input.text.length; }
        input.Keys.onEscapePressed: CaptureService.dismissSave()
      }

      Row {
        anchors.right: parent.right
        spacing: Theme.gapSmall

        KitButton {
          icon: "x"
          text: root.video ? "Default folder" : "Skip"
          onClicked: CaptureService.dismissSave()
        }

        KitButton {
          icon: "check"
          text: "Save"
          selected: true
          onClicked: CaptureService.confirmSave(path.text)
        }
      }
    }
  }
}
