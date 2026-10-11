import QtQuick
import Quickshell
import Quickshell.Hyprland

// mihomo widget — supersedes the old custom/vpn indicator (Vpn.qml is kept on
// disk but no longer placed in the bar). Shows "shield + VPN" and opens a
// rofi-style square-framed popup to pick the provider (proxy-provider) and the
// server (country), with two tabs, live traffic and per-server latency. The
// popup can also open mihomo's config (header gear) and a provider's own file
// (dots on the row) in the editor. Backed by MihomoService + scripts/mihomo.sh.

Item {
  id: root

  // the PanelWindow this item lives in — injected by Bar.qml
  required property var bar

  // track when the popup was last closed via HyprlandFocusGrab, to avoid
  // re-opening immediately on a double‑click (the composer may first fire
  // Cleared, then the module's own MouseArea fires).
  property real closedAt: 0

  // PopupWindow must be declared first so bindings referencing 'popup'
  // (onImplicitWidthChanged, HyprlandFocusGrab) resolve at init time.
  PopupWindow {
    id: popup

    anchor.window: root.bar
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left

    // Anchor the popup's top-right corner just under this module. Recomputed on
    // every show: mapToItem is not reactive and the module shifts as sibling
    // text changes. rect is relative to the anchor window's contentItem.
    anchor.onAnchoring: {
      const p = root.mapToItem(root.bar.contentItem, root.width, 0);
      anchor.rect.x = Math.round(p.x) - 1;
      anchor.rect.y = Theme.barHeight - 1;
      anchor.rect.width = 1;
      anchor.rect.height = 1 + Theme.popupGap;
    }

    color: "transparent"
    implicitWidth: Theme.popupWidth
    implicitHeight: content.implicitHeight
    visible: false
    grabFocus: false

    onVisibleChanged: {
      MihomoService.popupsOpen += visible ? 1 : -1;
      if (visible) MihomoService.refreshAll();
      else MihomoService.closeAddForm();
    }

    MihomoPopup {
      id: content
      anchors.fill: parent
      onCloseRequested: popup.visible = false
    }
  }

  Text {
    id: label
    text: MihomoService.barLabel()
    color: MihomoService.serviceOn ? Theme.green : Theme.muted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.bold: true
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  // The label's width settles asynchronously (emoji fallback fonts), and it
  // changes when the selected server changes. Keep the popup under the module.
  onImplicitWidthChanged: if (popup.visible) popup.anchor.updateAnchor()

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (popup.visible && Date.now() - root.closedAt < 300) {
        // ignore clicks within 300ms of a HyprlandFocusGrab clear
      } else {
        popup.visible = !popup.visible
      }
    }
  }

  // Hyprland-native outside-click dismissal. A layer-shell panel can't host a
  // grabbing xdg_popup, so grabFocus can't be used; hyprland_focus_grab_v1 is
  // the supported way to close on click-outside.
  HyprlandFocusGrab {
    id: grab
    windows: [popup]
    active: popup.visible
    onCleared: {
      root.closedAt = Date.now()
      popup.visible = false
    }
  }
}
