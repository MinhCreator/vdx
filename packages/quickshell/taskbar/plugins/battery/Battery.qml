import QtQuick
import Quickshell.Io
import qs.config

// battery (packages/waybar/modules/battery.jsonc + styles/battery.css):
//   format "{icon}  {capacity}" · charging  · plugged  · level 
//   warning <= 30 yellow · critical <= 15 red · charging green
//   default color foreground0 (styles/modules.css) · no on-click
//
// waybar reads sysfs directly (capacity from charge/energy_now, "Plugged" when a
// mains adapter is online, "Full" when charging at 100%). battery.sh replicates
// that exact logic and returns {"text":"<label>","class":"<class>"} so the bar
// shows identical text/colour; the class string selects the CSS colour here.

Item {
  id: root

  property string text: ""
  property string stateClass: ""

  readonly property color labelColor: {
    switch (root.stateClass) {
      case "charging": return Theme.green
      case "critical": return Theme.red
      case "warning":  return Theme.yellow
      default:         return Theme.foreground0
    }
  }

  Text {
    id: label
    text: root.text
    color: root.labelColor
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  Process {
    id: batProc
    command: ["bash", Theme.batteryScript]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const obj = JSON.parse(this.text.trim())
          root.text = obj.text !== undefined ? obj.text : ""
          root.stateClass = obj.class !== undefined ? obj.class : ""
        } catch (e) {
          root.text = ""
          root.stateClass = ""
        }
      }
    }
  }

  Timer {
    interval: Theme.batteryIntervalMs
    running: true
    repeat: true
    onTriggered: batProc.running = true
  }
}
