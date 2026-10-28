import QtQuick
import qs.config
import qs.kit
import qs.modules.battery
import qs.modules.sysmon

// The thin system strip: BAT, CPU, RAM, TEMP — a caption, one mono number, one
// form each (track for a level, the colour only when it says something).
Rectangle {
  id: root

  implicitHeight: 92
  radius: 22
  color: Theme.background1

  // the sampler runs while the strip is on screen
  property bool held: false
  onVisibleChanged: sync()
  Component.onCompleted: sync()
  Component.onDestruction: if (held) SysmonService.release()
  function sync() {
    if (visible === held) return;
    held = visible;
    if (held) SysmonService.hold(); else SysmonService.release();
  }

  readonly property real memGb: SysmonService.memUsed / 1073741824
  readonly property real memTotalGb: SysmonService.mem.total / 1073741824
  readonly property var cpuTemp: SysmonService.temps?.cpu ?? null

  Row {
    anchors { fill: parent; topMargin: 14; bottomMargin: 14; leftMargin: 4; rightMargin: 4 }

    Repeater {
      model: [
        { cap: "BAT", note: BatteryService.charging ? "charging" : "", num: String(BatteryService.capacity), unit: "%", frac: BatteryService.capacity / 100,
          tone: BatteryService.capacity <= BatteryService.critical ? Theme.red : BatteryService.charging ? Theme.purple : Theme.green },
        { cap: "CPU", note: SysmonService.cores.length + " cores", num: String(SysmonService.cpu), unit: "%", frac: SysmonService.cpu / 100, tone: Theme.foreground2 },
        { cap: "RAM", note: "of " + Math.round(root.memTotalGb) + " GB", num: root.memGb.toFixed(1), unit: "GB", frac: root.memTotalGb > 0 ? root.memGb / root.memTotalGb : 0, tone: Theme.foreground2 },
        { cap: "TEMP", note: "", num: root.cpuTemp !== null ? String(Math.round(root.cpuTemp)) : "—", unit: "°C", frac: root.cpuTemp !== null ? root.cpuTemp / 100 : 0,
          tone: root.cpuTemp !== null && root.cpuTemp >= 80 ? Theme.red : Theme.yellow }
      ]

      Item {
        required property var modelData
        required property int index
        width: parent.width / 4
        height: parent.height

        Rectangle { visible: parent.index > 0; width: 1; height: parent.height; color: Qt.rgba(1, 1, 1, 0.06) }

        Column {
          anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
          spacing: 10

          Item {
            width: parent.width
            height: 12
            KitText { text: modelData.cap; color: Theme.muted; font.pixelSize: 11; font.letterSpacing: 0.9 }
            KitText { anchors.right: parent.right; text: modelData.note; color: Theme.muted; font.pixelSize: 11 }
          }
          Row {
            spacing: 2
            KitText { text: modelData.num; font.pixelSize: 22; font.letterSpacing: -0.4 }
            KitText { text: modelData.unit; color: Theme.muted; font.pixelSize: 11; anchors.baseline: parent.children[0].baseline }
          }
          Item {
            width: parent.width
            height: 10
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 4; radius: 2; color: Theme.background3 }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * Math.max(0, Math.min(1, modelData.frac)); height: 4; radius: 2; color: modelData.tone }
          }
        }
      }
    }
  }
}
