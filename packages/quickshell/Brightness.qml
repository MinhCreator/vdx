import QtQuick
import Quickshell
import Quickshell.Io

// custom/brightness (gruvbox): JSON exec every 2s, color foreground0
// (modules.css). brightness.sh outputs {"text":"<icon>  <NN>","class":"on|off"}.
//   on-click       -> brightness.sh --toggle (hyprsunset)
//   on-scroll-up   -> brightnessctl set +5%
//   on-scroll-down -> brightnessctl set 5%-

Item {
  id: root

  property string text: ""

  Text {
    id: label
    text: root.text
    color: Theme.foreground0
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Process {
    id: brightProc
    command: ["bash", Theme.brightnessScript]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const obj = JSON.parse(this.text.trim())
          root.text = obj.text !== undefined ? obj.text : ""
        } catch (e) {
          root.text = ""
        }
      }
    }
  }

  Timer {
    interval: Theme.brightnessIntervalMs
    running: true
    repeat: true
    onTriggered: brightProc.running = true
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor // waybar: HAND2 when the module has events
    onClicked: {
      Quickshell.execDetached(["bash", Theme.brightnessScript, "--toggle"])
      brightProc.running = true
    }
  }

  WheelHandler {
    onWheel: (event) => {
      const delta = event.angleDelta.y
      if (delta > 0)
        Quickshell.execDetached(["brightnessctl", "set", "+" + Theme.brightnessScrollStep + "%"])
      else if (delta < 0)
        Quickshell.execDetached(["brightnessctl", "set", Theme.brightnessScrollStep + "%-"])
    }
  }
}