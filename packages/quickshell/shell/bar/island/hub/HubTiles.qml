import QtQuick
import Quickshell.Io
import qs.config
import qs.kit
import qs.modules.bluetooth
import qs.modules.mihomo
import qs.modules.wifi

// The four tiles: Wi-Fi, Bluetooth, VPN, Focus. A click flips the radio, the
// power or the service (Focus: mako's do-not-disturb); the module popups stay
// the bar modules'.
Grid {
  id: root

  columns: 4
  spacing: 8

  property bool dnd: false
  signal open(string module)

  Process {
    id: modeProc
    command: ["makoctl", "mode"]
    running: true
    stdout: StdioCollector { onStreamFinished: root.dnd = text.split("\n").includes("do-not-disturb") }
  }
  Process { id: modeSet }
  function toggleFocus() {
    modeSet.command = ["makoctl", "mode", dnd ? "-r" : "-a", "do-not-disturb"];
    modeSet.running = true;
    dnd = !dnd;
  }

  readonly property real cell: (width - 3 * spacing) / 4

  HubTile {
    width: root.cell
    title: "WI-FI"
    on: WifiService.connected
    tone: Theme.green
    value: WifiService.connected ? WifiService.ssid : (WifiService.radioOn ? "Not connected" : "Off")
    detail: WifiService.connected && WifiService.pingMs > 0 ? Math.round(WifiService.pingMs) + " ms" : ""
    onClicked: root.open("wifi")
  }
  HubTile {
    width: root.cell
    title: "BT"
    on: BluetoothService.powered && BluetoothService.mainDevice !== null
    tone: Theme.blue
    value: BluetoothService.mainDevice ? BluetoothService.mainDevice.name : (BluetoothService.powered ? "No device" : "Off")
    detail: BluetoothService.mainDevice && BluetoothService.mainDevice.battery != null ? BluetoothService.mainDevice.battery + "%" : ""
    onClicked: root.open("bluetooth")
  }
  HubTile {
    width: root.cell
    title: "VPN"
    on: MihomoService.serviceOn
    tone: Theme.green
    value: MihomoService.serviceOn ? "On" : "Off"
    detail: MihomoService.serviceOn ? MihomoService.current : ""
    onClicked: root.open("mihomo")
  }
  HubTile {
    width: root.cell
    title: "FOCUS"
    on: root.dnd
    tone: Theme.purple
    value: root.dnd ? "On" : "Off"
    detail: "DND"
    onClicked: root.toggleFocus()
  }
}
