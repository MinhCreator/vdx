import QtQuick
import qs.components
import qs.config
import qs.kit

// The Wi-Fi list view: header with the radio switch, the connection (address,
// signal, traffic, DNS), nearby networks, and actions in the footer.
Column {
  id: root
  // rows already on show: a new one eases in (KitAppear)
  property KitSeen seen: KitSeen {}
  signal closeRequested()

  readonly property var active: WifiService.networks.find(n => n.ssid === WifiService.ssid) ?? null
  readonly property int signal: active ? active.signal : 0
  readonly property string quality: signal >= 75 ? "Excellent" : signal >= 50 ? "Good"
                                  : signal >= 25 ? "Fair" : "Weak"
  // Modules › Wi-Fi › Compact popup: no connection details (address, signal, traffic, DNS)
  readonly property bool compact: ModuleSettings.get("wifi", "compact", false)
  readonly property bool measured: WifiService.connected && WifiService.pingMs > 0

  spacing: Theme.sectionGap

  // ---- header ----
  KitHeader {
    icon: WifiService.radioOn ? "wifi" : "wifi-off"
    iconColor: WifiService.connected ? Theme.foreground0 : Theme.muted
    title: WifiService.connected ? WifiService.ssid : "Wi-Fi"
    subtitle: !WifiService.radioOn ? "OFF"
      : WifiService.connected ? "CONNECTED"
      : "DISCONNECTED"

    KitBadge {
      anchors.verticalCenter: parent.verticalCenter
      visible: WifiService.radioOn
      text: WifiService.networks.length + " NEARBY"
      tint: Theme.muted
    }

    KitSwitch {
      anchors.verticalCenter: parent.verticalCenter
      checked: WifiService.radioOn
      onToggled: WifiService.toggleRadio()
    }
  }

  KitLine {}

  KitText {
    width: parent.width
    visible: WifiService.statusError !== "" || WifiService.radioError !== "" || WifiService.connectError !== ""
    text: WifiService.statusError || WifiService.radioError || WifiService.connectError
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }

  // ---- connection ----
  Column {
    width: parent.width
    visible: WifiService.connected && !root.compact
    spacing: Theme.gapLoose

    KitLabel { text: "CONNECTION"; value: WifiService.gateway ? "GATEWAY " + WifiService.gateway : "" }

    Item {
      width: parent.width
      height: address.implicitHeight

      KitText {
        id: address
        width: parent.width - quality.implicitWidth - 12
        text: "This PC  " + (WifiService.ipAddress || "—")
        elide: Text.ElideRight
      }

      KitText {
        id: quality
        anchors.right: parent.right
        text: root.measured ? "ping " + Math.round(WifiService.pingMs) + " ms · loss " + Math.round(WifiService.packetLoss) + "%" : "ping —"
        color: root.measured ? Theme.pingColor(WifiService.pingMs) : Theme.muted
        font.pixelSize: Theme.fontSize - 1
      }
    }

    Column {
      width: parent.width
      spacing: 5

      Item {
        width: parent.width
        height: signalText.implicitHeight

        KitText {
          id: signalText
          text: "Signal · " + root.quality
          color: Theme.foreground2
          font.pixelSize: Theme.fontSize - 1
        }

        KitText {
          anchors.right: parent.right
          text: root.signal + " %"
          color: Theme.foreground2
          font.pixelSize: Theme.fontSize - 1
        }
      }

      KitBar {
        value: root.signal / 100
        tint: Theme.qualityColor(root.signal, 60, 35)
      }
    }

    Item {
      width: parent.width
      height: traffic.implicitHeight

      KitText {
        id: traffic
        text: "Traffic now"
        color: Theme.foreground2
        font.pixelSize: Theme.fontSize - 1
      }

      KitText {
        anchors.right: parent.right
        text: "↓ " + Format.humanRate(WifiService.down) + "   ↑ " + Format.humanRate(WifiService.up)
        font.pixelSize: Theme.fontSize - 1
      }
    }
  }

  KitLine { visible: WifiService.connected && !root.compact }

  // ---- networks ----
  Column {
    width: parent.width
    spacing: Theme.gapMedium

    KitLabel {
      text: !WifiService.radioOn ? "WI-FI IS OFF" : "NETWORKS (" + WifiService.networks.length + ")"
    }

    Flickable {
      width: parent.width
      visible: WifiService.networks.length > 0
      height: Math.min(contentHeight, 30 * Theme.visibleRows)
      contentHeight: rows.implicitHeight
      interactive: contentHeight > height
      clip: true
      boundsBehavior: Flickable.StopAtBounds

      Column {
        id: rows
        width: parent.width

        Repeater {
          model: WifiService.networks
          // a network found by a scan eases in
          NetworkRow {
            id: net
            width: rows.width
            KitAppear { target: net; seen: root.seen; key: net.modelData.ssid }
          }
        }
      }
    }

    KitText {
      width: parent.width
      visible: WifiService.radioOn && WifiService.networks.length === 0
      text: WifiService.scanning ? "Looking for networks…" : WifiService.scanError || "No networks found. Try rescan."
      color: WifiService.scanError !== "" ? Theme.red : Theme.muted
      wrapMode: Text.WordWrap
    }
  }

  KitLine {}

  // ---- actions ----
  Row {
    width: parent.width
    spacing: Theme.gapMedium

    KitButton {
      id: rescan
      icon: "refresh"
      text: "Rescan"
      busy: WifiService.scanning
      disabled: !WifiService.radioOn || WifiService.scanning
      onClicked: WifiService.scan()
    }

    KitButton {
      width: parent.width - rescan.width - parent.spacing
      icon: "sliders"
      text: "Open settings"
      onClicked: {
        root.closeRequested();
        ShellIpc.call("shell", "open", ["network"]);
      }
    }
  }
}
