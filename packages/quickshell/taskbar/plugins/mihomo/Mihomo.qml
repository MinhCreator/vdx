import QtQuick
import Quickshell
import qs.bar
import qs.config

// mihomo widget — supersedes the old custom/vpn indicator (Vpn.qml has been
// removed; the waybar vpn module is now this popup). Shows "shield + VPN" and
// opens a rofi-style square-framed popup to pick the provider (proxy-provider)
// and the server (country), with two tabs, live traffic and per-server
// latency. The popup can also open mihomo's config (header gear) and a
// provider's own file (dots on the row) in the editor. Backed by MihomoService
// + scripts/mihomo.sh.

Item {
  id: root

  // the PanelWindow this item lives in — injected by Bar.qml
  required property PanelWindow bar

  BarPopup {
    id: popup
    anchorItem: root
    bar: root.bar
    implicitHeight: content.implicitHeight

    onShown: {
      MihomoService.popupsOpen += 1;
      MihomoService.refreshAll();
    }
    onHidden: {
      MihomoService.popupsOpen -= 1;
      MihomoService.closeAddForm();
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
    font.weight: Theme.fontWeight
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
      // The outside-click that closed the popup arrives here a beat after
      // HyprlandFocusGrab / the Wayland grab already hid it. Swallow that
      // echo instead of toggling the popup back open.
      if (Date.now() - popup.closedAt < 300) return;
      popup.visible = !popup.visible;
    }
  }
}
