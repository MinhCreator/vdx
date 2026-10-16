import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// VirusTotal as a window of its own (how it opens: Shell Manager › Shell
// apps, scripts/shellapps.py writes the rule). `qs -c shell ipc call
// virustotal <toggle|open|close>`; Escape closes.
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
