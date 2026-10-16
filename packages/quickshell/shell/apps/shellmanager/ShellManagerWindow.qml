import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The Shell Manager as a window of its own (its window rule comes from scripts/shellapps.py (Shell Manager › Shell apps)). Opened
// from the bar's Shell button, Super+S, `qs -c shell ipc call shell toggle` or
// `… shell open <page>[:<group or app>]` (appearance, bar, windows, modules,
// apps, launcher, keybinds, lock, about); Escape closes it.
FloatingWindow {
  id: root

  title: "Shell Manager"
  visible: ShellSettings.managerOpen
  implicitWidth: 820
  implicitHeight: 600
  color: Theme.background0

  onVisibleChanged: {
    if (visible) ThemeService.refresh();     // themes added since start show up
    else ShellSettings.managerOpen = false;
  }

  ShellManager {
    id: manager
    anchors.fill: parent
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    enabled: !manager.dialogOpen          // Escape closes the dialog first
    onActivated: ShellSettings.managerOpen = false
  }

  IpcHandler {
    target: "shell"
    function toggle(): void { ShellSettings.managerOpen = !ShellSettings.managerOpen; }
    // `open <page>`, or `open <page>:<group or app>` (apps:taskmanager,
    // bar:layout); the old page names still work
    function open(page: string): void {
      const [p, target] = page.split(":");
      ShellSettings.managerOpen = true;
      manager.navigate(({ themes: "appearance", wallpaper: "appearance", layout: "bar" })[p] ?? p, target ?? "");
    }
  }
}
