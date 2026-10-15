import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The package manager as a window of its own (how it opens: Shell Manager ›
// Shell apps). `qs -c shell ipc call packages <toggle|open|close>`; Escape
// closes. Opening refreshes the lists. Hyprland floats it by its title
// (hypr/components/rules.lua).
FloatingWindow {
  id: root

  title: "Packages"
  visible: false
  implicitWidth: 820
  implicitHeight: 620
  color: Theme.background0

  // each time it opens: on the option's tab, the lists up to date
  onVisibleChanged: if (visible) {
    content.tab = PackagesService.opt("startTab", "updates");
    PackagesService.freshen(false);
  }

  Packages {
    id: content
    anchors.fill: parent
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: root.visible = false
  }

  IpcHandler {
    target: "packages"
    function toggle(): void { root.visible = !root.visible; }
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
  }
}
