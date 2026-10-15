import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The Shell Manager as a window of its own (Hyprland floats and centres it by
// its title, see hypr/components/rules.lua). Opened from the bar's shell
// button, Super+S, `qs -c shell ipc call shell toggle` or `… shell open <tab>`
// (themes | wallpaper | bar | modules); Escape closes it.
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
    // `open <tab>`, or `open <tab>:<group or app>` (apps:taskmanager, bar:layout)
    function open(tab: string): void {
      const [t, target] = tab.split(":");
      ShellSettings.managerOpen = true;
      manager.navigate(({ appearance: "themes", layout: "bar" })[t] ?? t, target ?? "");
    }
  }
}
