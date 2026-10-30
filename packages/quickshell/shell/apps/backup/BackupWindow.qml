import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config

// The backups as a window of its own (how it opens: Shell apps).
// `qs -c shell ipc call backup <toggle|open|close>`; Escape closes.
// Opening reads the status and the snapshots; while open, the status is
// read again each minute (a timed run may have finished).
FloatingWindow {
  id: root

  title: "Backups"
  visible: false
  implicitWidth: 1060
  implicitHeight: 640
  color: Theme.background0

  // Hyprland closing the window hides it but leaves FloatingWindow's own
  // visible set, so the next `visible = true` would do nothing: reset it.
  onVisibleChanged: if (visible) {
    BackupService.refresh();
    BackupService.loadSnapshots();
    BackupService.loadSize();
  } else visible = false;

  Timer {
    interval: 60000
    repeat: true
    running: root.visible
    onTriggered: BackupService.refresh()
  }

  Loader {
    anchors.fill: parent
    active: root.visible
    sourceComponent: Component { Backup { anchors.fill: parent } }
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "backup"
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
