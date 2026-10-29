import QtQuick
import qs.config
import qs.kit

// Network › Hotspot: this machine shares its connection over Wi-Fi.
KitColumn {
  id: root

  required property var page    // the Network page

  readonly property var ws: page.ws
  readonly property var hs: page.hs

  property bool armed: false      // a second click confirms
  Timer { id: disarm; interval: 3000; onTriggered: root.armed = false }

  spacing: Theme.gapGroup

  // ---- hotspot: this machine shares its connection over Wi-Fi ----
  KitLabel {
    id: hotspotGroup
    text: "HOTSPOT"
    value: hs?.active ? "ON · " + hs.clients + " CLIENTS" : "OFF"
  }

  KitRow {
    label: "Hotspot"
    hint: !hs?.supported ? "This Wi-Fi card cannot host one"
      : !hs?.uuid ? "Set a password first"
      : "Wi-Fi drops while it is on"

    KitButton {
      width: Theme.buttonWidth
      text: hs?.active ? "Stop" : root.armed ? "Sure?" : "Start"
      busy: ws.hotspotBusy
      disabled: !ws.radioOn || !(hs?.supported ?? false) || !(hs?.uuid ?? "") || ws.hotspotBusy
      onClicked: {
        if (hs?.active) {
          ws.setHotspot(false);
        } else if (ws.connected && !root.armed) {
          root.armed = true;
          disarm.restart();
        } else {
          root.armed = false;
          ws.setHotspot(true);
        }
      }
    }
  }

  KitRow {
    wide: true
    label: "Name"
    hint: "The network the phones see"

    KitInput {
      enabled: !ws.hotspotBusy
      text: hs?.ssid ?? ""
      placeholder: "name"
      onAccepted: ws.setHotspotSetting("ssid", text)
    }
  }

  KitRow {
    wide: true
    label: "Password"
    hint: "8 characters or more"

    KitInput {
      enabled: !ws.hotspotBusy
      placeholder: "password"
      echoMode: TextInput.Password
      onAccepted: {
        ws.setHotspotSetting("password", text);
        text = "";
      }
    }
  }

  KitRow {
    wide: true
    label: "Channel"
    hint: "Auto picks a free one"

    KitSegments {
      disabled: ws.hotspotBusy
      model: [{ label: "Auto", value: "auto" }, { label: "1", value: "1" }, { label: "6", value: "6" }, { label: "11", value: "11" }]
      current: (hs?.channel ?? "0") === "0" ? "auto" : hs?.channel
      onPicked: value => ws.setHotspotSetting("channel", value)
    }
  }

  KitText {
    visible: ws.hotspotError !== ""
    text: ws.hotspotError
    color: Theme.red
    wrapMode: Text.WordWrap
  }

  KitGrouper {}
}
