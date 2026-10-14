import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.components
import qs.config

// Popup chrome shared by every bar module: anchoring under the module, one open
// popup across the bar (PopupManager), keyboard focus for inputs and
// outside-click dismissal (HyprlandFocusGrab).
//
// The signals are `shown` / `hidden` because PopupWindow already owns `opened`
// and `closed`; redeclaring them trips qt.qml.invalidOverride.
PopupWindow {
  id: root

  required property Item anchorItem
  required property PanelWindow bar

  // `qs -c taskbar ipc call <ipcTarget> toggle` opens / closes the popup
  // (Hyprland binds, checks). Empty disables it.
  property string ipcTarget: ""

  // Escape closes the popup. A popup with its own Escape handling (nested
  // views going back first) turns this off.
  property bool closeOnEscape: true

  // Modules in the left half grow their popup to the right from their left
  // edge, the rest to the left from their right edge; set on every anchoring.
  property bool alignLeft: false

  // When the popup last closed. The outside click that closes it also reaches
  // the module right after; toggle() ignores that echo.
  property real closedAt: 0

  signal shown()
  signal hidden()

  function toggle() {
    if (Date.now() - closedAt > 300) visible = !visible;
  }

  anchor.window: root.bar
  anchor.edges: Edges.Bottom | (alignLeft ? Edges.Left : Edges.Right)
  anchor.gravity: Edges.Bottom | (alignLeft ? Edges.Right : Edges.Left)

  // Bar x of the popup's corner, fixed while it is open (-1: closed).
  property real anchorX: -1

  // A corner under the module, taken once per show: modules change width while
  // the popup is open (track titles, values) and the popup must not follow.
  anchor.onAnchoring: {
    if (root.anchorX < 0) {
      root.alignLeft = root.anchorItem.mapToItem(root.bar.contentItem, root.anchorItem.width / 2, 0).x
                       < root.bar.width / 2;
      const p = root.anchorItem.mapToItem(root.bar.contentItem, root.alignLeft ? 0 : root.anchorItem.width, 0);
      root.anchorX = Math.round(p.x) - 1;
    }
    anchor.rect.x = root.anchorX;
    anchor.rect.y = Theme.barHeight - 1;
    anchor.rect.width = 1;
    anchor.rect.height = 1 + Theme.popupGap;
  }

  color: "transparent"
  visible: false
  // No xdg popup grab: the compositor would dismiss the popup whenever another
  // surface takes focus (slurp) and swallow the click on another module.
  // Keyboard focus comes from HyprlandFocusGrab, outside clicks from
  // PopupCatcher.
  grabFocus: false

  onVisibleChanged: {
    if (visible) {
      PopupManager.open(root);
      root.shown();
    } else {
      root.closedAt = Date.now();
      root.anchorX = -1;
      PopupManager.close(root);
      root.hidden();
    }
  }

  Shortcut {
    sequences: [StandardKey.Cancel]
    context: Qt.WindowShortcut
    enabled: root.visible && root.closeOnEscape
    onActivated: root.visible = false
  }

  IpcHandler {
    target: root.ipcTarget
    enabled: root.ipcTarget !== ""
    function toggle(): void { root.toggle(); }
  }

  // hidden, not closed, while the capture overlay's still copy stands in for it
  Binding {
    target: root.contentItem
    property: "opacity"
    value: PopupManager.frozen ? 0 : 1
  }

  HyprlandFocusGrab {
    windows: [root]
    active: root.visible && !PopupManager.holding
    onCleared: if (!PopupManager.holding) root.visible = false
  }
}
