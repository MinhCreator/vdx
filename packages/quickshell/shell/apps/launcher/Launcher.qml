import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.bar.island
import qs.components
import qs.config

// The launcher (Alt+Space), like rofi: the screen dims and the panel
// (LauncherPanel) floats in the middle. Escape or a click on the dimmed screen
// closes. The same panel runs inside the island (Island › Launcher).
ScrimWindow {
  id: root

  readonly property var ls: LauncherService
  readonly property int panelWidth: ({ small: 520, medium: 640, large: 800 })[ModuleSettings.get("launcher", "size", "medium")] ?? 640
  readonly property string position: ModuleSettings.get("launcher", "position", "top")

  function close() { ls.open = false; }

  // Island style with "Open from the island": the launcher opens inside the island instead of this window
  readonly property bool fromIsland: ShellSettings.barStyle === "island" && ModuleSettings.get("launcher", "island", true)

  open: ls.open && !root.fromIsland
  dim: ModuleSettings.get("launcher", "dim", true)
  namespace: "launcher"
  onDismissed: close()

  Connections {
    target: root.ls
    function onOpenChanged() {
      if (!root.ls.open) return;
      if (root.fromIsland) { root.ls.open = false; IslandService.requested("launcher", Hyprland.focusedMonitor?.name ?? ""); return; }
      panel.reset();
    }
  }

  Item {
    anchors.fill: parent

    // clicks on the panel don't reach the dimmed screen
    MouseArea { anchors.fill: panel }

    LauncherPanel {
      id: panel
      anchors.horizontalCenter: parent.horizontalCenter
      y: root.position === "center" ? (parent.height - height) / 2
       : root.position === "bottom" ? parent.height * 0.82 - height
       : parent.height * 0.18
      width: root.panelWidth
      onBack: root.close()
      onFinished: root.close()
    }
  }
}
