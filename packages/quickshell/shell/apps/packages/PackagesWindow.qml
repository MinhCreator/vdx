import QtQuick
import Quickshell
import Quickshell.Io
import qs.components
import qs.config

// The package manager as a window of its own (how it opens: Shell Manager ›
// Shell apps, scripts/shellapps.py writes the rule). `qs -c shell ipc call
// packages <toggle|open|close>`; Escape closes. Opening refreshes the lists.
FloatingWindow {
  id: root

  title: "Packages"
  visible: false
  implicitWidth: 820
  implicitHeight: 620
  color: Theme.background0

  // Hyprland closing the window (Super+C) hides it but leaves FloatingWindow's
  // own visible set, so the next `visible = true` would do nothing: reset it.
  // each time it opens: on the option's tab, the lists up to date
  onVisibleChanged: if (visible) {
    Qt.callLater(() => { if (content.item) content.item.tab = PackagesService.opt("startTab", "updates"); });
    PackagesService.freshen(false);
    Qt.callLater(() => PopupManager.closeModule("packages"));
  } else visible = false;

  Loader {
    id: content
    anchors.fill: parent
    active: root.visible
    sourceComponent: Component { Packages { anchors.fill: parent } }
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "packages"
    function toggle(): void { Hypr.toggleWindow(root); }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
