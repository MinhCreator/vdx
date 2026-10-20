import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.bar.island
import qs.components
import qs.config

// The keybinds, floating over the dimmed screen like the launcher (Super+B): the panel
// (KeybindsPanel) in the middle. Escape or a click on the dimmed screen closes. The same
// panel runs inside the island (Island › Keys).
ScrimWindow {
  id: root

  readonly property var kb: KeybindsService
  readonly property int panelWidth: ({ small: 520, medium: 640, large: 800 })[ModuleSettings.get("keybinds", "size", "medium")] ?? 640
  readonly property string position: ModuleSettings.get("keybinds", "position", "top")

  function close() { kb.open = false; }

  // Island style with "Open from the island": the keybinds open inside the island instead of this window
  readonly property bool fromIsland: ShellSettings.barStyle === "island" && ModuleSettings.get("keybinds", "island", true)

  open: kb.open && !root.fromIsland
  dim: ModuleSettings.get("keybinds", "dim", true)
  namespace: "keybinds"
  onDismissed: close()

  Connections {
    target: root.kb
    function onOpenChanged() {
      if (!root.kb.open) return;
      if (root.fromIsland) { root.kb.open = false; IslandService.requested("keybinds", Hyprland.focusedMonitor?.name ?? ""); return; }
      panel.reset();
    }
  }

  Item {
    anchors.fill: parent

    // clicks on the panel don't reach the dimmed screen
    MouseArea { anchors.fill: panel }

    KeybindsPanel {
      id: panel
      anchors.horizontalCenter: parent.horizontalCenter
      y: root.position === "center" ? (parent.height - height) / 2
       : root.position === "bottom" ? parent.height * 0.82 - height
       : parent.height * 0.18
      width: root.panelWidth
      onBack: root.close()
    }
  }
}
