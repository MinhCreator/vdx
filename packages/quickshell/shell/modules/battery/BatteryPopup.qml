import QtQuick
import qs.config
import qs.kit

// Battery: charge and health, then the power saver switch (the profile, the charge limit
// and the GPU mode are in Settings › Power).
KitFrame {
  id: root

  // Modules › Battery › Compact popup: no health, cycles and energy
  readonly property bool compact: ModuleSettings.get("battery", "compact", false)
  readonly property string timeLeft: BatteryService.minutesLeft < 0 ? "—"
    : Math.floor(BatteryService.minutesLeft / 60) + ":" + String(BatteryService.minutesLeft % 60).padStart(2, "0")
  readonly property string summary: BatteryService.charging ? "CHARGING · " + timeLeft + " TO " + BatteryService.threshold + "%"
    : BatteryService.discharging ? "DISCHARGING · " + timeLeft + " LEFT"
    : BatteryService.plugged ? "PLUGGED IN" + (BatteryService.limitSupported ? " · LIMIT " + BatteryService.threshold + "%" : "")
    : "IDLE"
  readonly property color levelColor: BatteryService.capacity <= BatteryService.critical ? Theme.red
    : BatteryService.capacity <= BatteryService.warning ? Theme.yellow : Theme.green
  // ---- header ----
  KitHeader {
    icon: BatteryService.saver ? "battery-saver" : BatteryService.charging ? "battery-bolt"
      : BatteryService.plugged ? "battery-plugged" : BatteryService.levelIcon
    iconColor: BatteryService.capacity <= BatteryService.critical && !BatteryService.plugged ? Theme.red : Theme.foreground0
    title: "Battery"
    subtitle: root.summary

    KitBadge {
      anchors.verticalCenter: parent.verticalCenter
      text: BatteryService.capacity + "%"
      tint: root.levelColor
    }
  }

  KitLine {}

  // ---- charge ----
  Column {
    width: parent.width
    spacing: Theme.gapMedium

    KitLabel {
      text: "CHARGE"
      value: BatteryService.power > 0 ? BatteryService.power.toFixed(1) + " W" : "IDLE"
    }

    KitBar {
      value: BatteryService.capacity / 100
      tint: root.levelColor
    }

    Item { visible: !root.compact; width: 1; height: 2 }

    KitInfo {
      visible: !root.compact
      label: "Health"
      value: BatteryService.health + "%"
      valueColor: Theme.qualityColor(BatteryService.health, 80, 60)
    }

    KitInfo { visible: !root.compact; label: "Cycles"; value: String(BatteryService.cycles) }

    KitInfo {
      visible: !root.compact
      label: "Energy"
      value: BatteryService.energy.toFixed(1) + " / " + BatteryService.energyDesign.toFixed(1) + " Wh"
    }
  }

  KitLine {}

  // ---- power saver ----
  KitRow {
    width: parent.width
    visible: BatteryService.profiles.length > 0
    label: "Power saver"
    hint: "Quiet profile, slower and cooler"
    KitSwitch {
      accessibleName: "Power saver"
      checked: BatteryService.saver
      onToggled: BatteryService.setSaver(!BatteryService.saver)
    }
  }

  KitText {
    width: parent.width
    visible: BatteryService.error !== ""
    text: BatteryService.error
    color: Theme.red
    wrapMode: Text.WordWrap
    font.pixelSize: Theme.fontSize - 1
  }
}
