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

  columns: 2
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

  readonly property real cell: (width - spacing) / 2

  HubTile {
    width: root.cell
    icon: WifiService.connected ? "wifi" : "wifi-off"
    title: "Wi-Fi"
    on: WifiService.connected
    detail: WifiService.connected ? WifiService.ssid : (WifiService.radioOn ? "Not connected" : "Off")
    onClicked: root.open("wifi")
  }
  HubTile {
    width: root.cell
    icon: BluetoothService.powered ? "bluetooth" : "bluetooth-off"
    title: BluetoothService.mainDevice ? BluetoothService.mainDevice.name : "Bluetooth"
    on: BluetoothService.powered && BluetoothService.mainDevice !== null
    detail: BluetoothService.mainDevice
      ? (BluetoothService.mainDevice.battery != null ? BluetoothService.mainDevice.battery + "%" : "Connected")
      : (BluetoothService.powered ? "No device" : "Off")
    onClicked: root.open("bluetooth")
  }
  HubTile {
    width: root.cell
    icon: "shield"
    title: "VPN"
    on: MihomoService.serviceOn
    detail: MihomoService.serviceOn ? (MihomoService.current || "On") : "Off"
    onClicked: root.open("mihomo")
  }
  HubTile {
    width: root.cell
    icon: "moon"
    title: "Focus"
    on: root.dnd
    detail: root.dnd ? "Do not disturb" : "Off"
    onClicked: root.toggleFocus()
  }
}
