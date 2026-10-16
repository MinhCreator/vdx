import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config

// The cleaner as a window of its own (how it opens: Shell Manager › Shell
// apps). Super+X or `qs -c shell ipc call cleaner <toggle|open|close>`;
// Escape closes. Opening rescans when the last scan is over a minute old.
FloatingWindow {
  id: root

  title: "Cleaner"
  visible: false
  implicitWidth: 760
  implicitHeight: 620
  color: Theme.background0

  onVisibleChanged: if (visible) CleanerService.freshen()

  Cleaner {
    anchors.fill: parent
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "cleaner"
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
