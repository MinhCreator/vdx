import QtQuick
import Quickshell
import Quickshell.Io

// network (mirrors modules/network.jsonc + network.css):
//   format-wifi         "  {essid}"
//   format-ethernet     ""            (hidden)
//   format-disconnected "Disconnected"
//   interval 5 · on-click kitty -e wifitui
// Color: foreground0; gray when disconnected.
//
// Implemented with a tiny nmcli wrapper (network.sh) instead of
// Quickshell.Networking to keep waybar's exact output semantics.

Item {
  id: root

  property string text: ""

  readonly property bool disconnected: root.text === "Disconnected"

  Text {
    id: label
    text: root.text
    color: root.disconnected ? Theme.gray : Theme.foreground0
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Process {
    id: netProc
    command: ["bash", Theme.networkScript]
    running: true

    stdout: StdioCollector {
      onStreamFinished: root.text = this.text.trim()
    }
  }

  Timer {
    interval: Theme.networkIntervalMs
    running: true
    repeat: true
    onTriggered: netProc.running = true
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor // waybar: HAND2 when the module has events
    onClicked: Quickshell.execDetached(["kitty", "-e", "wifitui"])
  }
}