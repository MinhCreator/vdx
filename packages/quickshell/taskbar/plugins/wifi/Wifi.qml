import QtQuick
import Quickshell
import qs.bar
import qs.config

// wifi widget — shows "wifi-glyph + SSID" (green when connected, normal
// foreground otherwise) and opens a rofi-style square-framed popup: Wi-Fi on
// switch, connection details, DNS provider, known / other networks, password
// form for a new SSID, and a QR share of the current network. Backed by
// WifiService + scripts/wifi.sh (NetworkManager).

Item {
  id: root

  required property PanelWindow bar

  BarPopup {
    id: popup
    anchorItem: root
    bar: root.bar
    implicitHeight: content.implicitHeight

    onShown: {
      WifiService.popupsOpen += 1;
      WifiService.popupOpened();
    }
    onHidden: {
      WifiService.popupsOpen -= 1;
      WifiService.resetView();
    }

    WifiPopup {
      id: content
      anchors.fill: parent
    }
  }

  Text {
    id: label
    text: WifiService.barLabel()
    color: WifiService.connected ? Theme.green : Theme.foreground0
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  onImplicitWidthChanged: if (popup.visible) popup.anchor.updateAnchor()

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (Date.now() - popup.closedAt < 300) return;
      popup.visible = !popup.visible;
    }
  }
}