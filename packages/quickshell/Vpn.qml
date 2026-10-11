import QtQuick
import Quickshell
import Quickshell.Io

// custom/vpn (gruvbox vpn.jsonc + vpn.css):
//   JSON exec every 2s {"text":"VPN","class":"connected|disconnected"}
//   on-click -> vpn.sh --toggle
// Color: green connected · gray disconnected

Item {
  id: root

  property string text: ""
  property string mode: "disconnected"

  readonly property bool connected: root.mode === "connected"

  Text {
    id: label
    text: root.text !== "" ? root.text : "VPN"
    color: root.connected ? Theme.green : Theme.gray
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Process {
    id: vpnProc
    command: ["bash", Theme.vpnScript]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const obj = JSON.parse(this.text.trim())
          root.text = obj.text !== undefined ? obj.text : "VPN"
          root.mode = obj.class !== undefined ? obj.class : "disconnected"
        } catch (e) {
          root.mode = "disconnected"
        }
      }
    }
  }

  Timer {
    interval: Theme.vpnIntervalMs
    running: true
    repeat: true
    onTriggered: vpnProc.running = true
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor // waybar: HAND2 when the module has events
    onClicked: {
      Quickshell.execDetached(["bash", Theme.vpnScript, "--toggle"])
      vpnProc.running = true
    }
  }
}