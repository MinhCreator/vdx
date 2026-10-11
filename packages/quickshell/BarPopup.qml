import QtQuick
import Quickshell
import Quickshell.Hyprland

// BarPopup — the chrome every bar module's popup shares.
//
// Wraps a PopupWindow and handles everything modules would otherwise repeat:
// anchoring under the module, registering with PopupManager (only one popup
// open across the bar), grabbing keyboard focus (so TextInputs inside are
// typable) and outside-click dismissal via HyprlandFocusGrab.
//
// The dismiss signals are named `shown` / `hidden` — not `opened` / `closed` —
// because PopupWindow already declares signals by those names, and overriding
// them trips qt.qml.invalidOverride.

PopupWindow {
  id: root

  required property Item anchorItem
  required property PanelWindow bar

  // Timestamp of the last close (outside-click, ESC, button). The module's
  // MouseArea compares Date.now() against it to skip the click the compositor
  // delivers to the bar right after the popup disappears — otherwise that click
  // would immediately reopen the popup it just closed.
  property real closedAt: 0

  signal shown()
  signal hidden()

  anchor.window: root.bar
  anchor.edges: Edges.Bottom | Edges.Right
  anchor.gravity: Edges.Bottom | Edges.Left

  // Anchor the popup's top-right corner just under this module. Recomputed on
  // every show: mapToItem is not reactive and the module shifts as sibling text
  // changes. The rect is relative to the anchor window's contentItem.
  anchor.onAnchoring: {
    const p = root.anchorItem.mapToItem(root.bar.contentItem, root.anchorItem.width, 0);
    anchor.rect.x = Math.round(p.x) - 1;
    anchor.rect.y = Theme.barHeight - 1;
    anchor.rect.width = 1;
    anchor.rect.height = 1 + Theme.popupGap;
  }

  color: "transparent"
  implicitWidth: Theme.popupWidth
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

  // Hyprland-native outside-click dismissal.
  HyprlandFocusGrab {
    id: grab
    windows: [root]
    active: root.visible
    onCleared: root.visible = false
  }
}
