import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config

// The clipboard history as a window of its own (how it opens: Shell Manager ›
// Shell apps). `qs -c shell ipc call clipboard <toggle|open|close>` or the
// launcher; Escape closes. Opening reads the history again.
FloatingWindow {
  id: root

  title: "Clipboard"
  visible: false
  implicitWidth: 480
  implicitHeight: 560
  color: Theme.background0

  // Hyprland closing the window (Super+C) hides it but leaves FloatingWindow's
  // own visible set, so the next `visible = true` would do nothing: reset it.
  onVisibleChanged: if (visible) {
    ClipboardService.refresh();
    Qt.callLater(() => PopupManager.closeModule("clipboard"));
  } else visible = false;

  // the same content as the bar's popup, in the window's look (flat, like Cleaner)
  Clipboard {
    anchors.fill: parent
    framed: false
    padding: Theme.windowPadding
    headerInset: Theme.headerInset
    onPicked: root.visible = false
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "clipboard"
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
