import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
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

  onVisibleChanged: if (visible) PopupManager.closeModule("virustotal");

  VirusTotal {
    anchors.fill: parent
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "virustotal"
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
