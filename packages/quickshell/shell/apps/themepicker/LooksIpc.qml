import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.bar.island
import qs.components
import qs.config

// Super+T: the island's Themes / Wallpapers pair (LooksPanel); with another bar style the
// Themes popup of the bar, when the module sits there. `qs -c shell ipc call themepicker toggle`
Scope {
  IpcHandler {
    target: "themepicker"
    function toggle(): void {
      if (Theme.island) IslandService.requested("looks", Hyprland.focusedMonitor?.name ?? "");
      else if (PopupManager.ipcOwner("themes")) ShellIpc.call("themes", "toggle");
    }
  }
}
