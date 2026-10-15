import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// VirusTotal as a window of its own (how it opens: Shell Manager › Shell
// apps). `qs -c shell ipc call virustotal <toggle|open|close>`; Escape closes.
// Hyprland floats and centres it by its title (hypr/components/rules.lua).
FloatingWindow {
  id: root

  title: "VirusTotal"
  visible: false
  implicitWidth: 640
  implicitHeight: 600
  color: Theme.background0

  VirusTotal {
    anchors.fill: parent
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "virustotal"
    function toggle(): void { root.visible = !root.visible; }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
