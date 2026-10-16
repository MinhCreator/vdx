import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config

// The display settings as a window of its own (how it opens: Shell Manager ›
// Shell apps). `qs -c shell ipc call display <toggle|open|close>`; Escape closes.
// Opening refreshes the monitors.
FloatingWindow {
  id: root

  title: "Display"
  visible: false
  implicitWidth: 520
  implicitHeight: content.implicitHeight
  color: Theme.background0

  // see PackagesWindow: Hyprland closing it leaves the visible flag set
  onVisibleChanged: if (visible) {
    DisplayService.refresh();
    Qt.callLater(() => PopupManager.closeModule("display"));
  } else visible = false;

  Display {
    id: content
    anchors.fill: parent
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "display"
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
