import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The Shell Manager as a window of its own (Hyprland floats and centres it by
// its title, see hypr/components/rules.lua). Opened from the bar's shell
// button, `qs -c taskbar ipc call shell toggle` or `… shell open <tab>`
// (appearance | plugins | layout); Escape closes it.
FloatingWindow {
  id: root

  title: "Shell Manager"
  visible: ShellSettings.managerOpen
  implicitWidth: Theme.popupWidthWide
  implicitHeight: 640
  color: Theme.background0

  onVisibleChanged: {
    if (visible) ThemeService.refresh();     // themes added since start show up
    else ShellSettings.managerOpen = false;
  }

  ShellManager {
    id: manager
    anchors.fill: parent
    border.width: 0
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    onActivated: ShellSettings.managerOpen = false
  }

  IpcHandler {
    target: "shell"
    function toggle(): void { ShellSettings.managerOpen = !ShellSettings.managerOpen; }
    function open(tab: string): void {
      manager.tab = tab;
      ShellSettings.managerOpen = true;
    }
  }
}
