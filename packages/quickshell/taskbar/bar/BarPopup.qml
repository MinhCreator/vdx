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

  // Grow to the right from the module's left edge instead of to the left from
  // its right edge — for modules on the left whose width changes (music).
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

  // A corner under the module. mapToItem isn't reactive, so this runs on every
  // show and whenever the module's width changes.
  anchor.onAnchoring: {
    const p = root.anchorItem.mapToItem(root.bar.contentItem, root.alignLeft ? 0 : root.anchorItem.width, 0);
    anchor.rect.x = Math.round(p.x) - 1;
    anchor.rect.y = Theme.barHeight - 1;
    anchor.rect.width = 1;
    anchor.rect.height = 1 + Theme.popupGap;
  }

  color: "transparent"
  visible: false
  grabFocus: true

  onVisibleChanged: {
    if (visible) {
      PopupManager.open(root);
      root.shown();
    } else {
      root.closedAt = Date.now();
      PopupManager.close(root);
      root.hidden();
    }
  }

  Connections {
    target: root.anchorItem
    function onWidthChanged() { if (root.visible) root.anchor.updateAnchor(); }
  }

  IpcHandler {
    target: root.ipcTarget
    enabled: root.ipcTarget !== ""
    function toggle(): void { root.toggle(); }
  }

  HyprlandFocusGrab {
    windows: [root]
    active: root.visible
    onCleared: root.visible = false
  }
}
