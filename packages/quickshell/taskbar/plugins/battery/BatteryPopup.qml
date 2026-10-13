import QtQuick
import qs.components
import qs.config

PopupFrame {
  id: root

  property string icon: ""

  readonly property string timeLeft: BatteryService.minutesLeft < 0 ? "—"
    : Math.floor(BatteryService.minutesLeft / 60) + ":" + String(BatteryService.minutesLeft % 60).padStart(2, "0")
  readonly property string summary: BatteryService.charging ? "CHARGING · " + timeLeft + " TO " + BatteryService.threshold + "%"
    : BatteryService.discharging ? "DISCHARGING · " + timeLeft + " LEFT"
    : BatteryService.plugged ? "PLUGGED IN · LIMIT " + BatteryService.threshold + "%"
    : "IDLE"
  readonly property real columnWidth: (width - 2 * inset - 16) / 2
  readonly property var dropdowns: [limit, profile, gpu]

  // At most one dropdown open at a time.
  function collapseOthers(open) {
    for (const d of dropdowns) if (d !== open) d.expanded = false;
  }

  // ---- header ----------------------------------------------------------------
  PopupHeader {
    width: parent.width
    glyph: root.icon
    glyphColor: BatteryService.saver ? Theme.aqua : Theme.foreground0
    title: "BATTERY"
    subtitle: root.summary
    subtitleColor: BatteryService.charging || BatteryService.plugged ? Theme.green
      : BatteryService.capacity <= Theme.batteryCritical ? Theme.red
      : Theme.foreground2

    // Power saver: the quiet profile, shown as the leaf icon.
    PopupSwitch {
      visible: BatteryService.profiles.includes(Theme.powerSaverProfile)
      checked: BatteryService.saver
      onToggled: BatteryService.setSaver(!BatteryService.saver)
    }
  }

  PopupSeparator { width: parent.width }

  // ---- info ------------------------------------------------------------------
  Row {
    width: parent.width
    spacing: 16

    PopupInfoList {
      width: root.columnWidth
      model: [
        { label: "CHARGE", value: BatteryService.capacity + "%" },
        { label: "POWER",  value: BatteryService.power > 0 ? BatteryService.power.toFixed(1) + " W" : "—" },
        { label: "HEALTH", value: BatteryService.health + "%",
          color: Theme.qualityColor(BatteryService.health, 80, 60) },
        { label: "ENERGY", value: BatteryService.energy.toFixed(1) + " Wh" }
      ]
    }

    PopupInfoList {
      width: root.columnWidth
      model: [
        { label: "STATUS", value: BatteryService.info.status ?? "—" },
        { label: "TIME",   value: root.timeLeft },
        { label: "CYCLES", value: String(BatteryService.cycles) },
        { label: "DESIGN", value: BatteryService.energyDesign.toFixed(1) + " Wh" }
      ]
    }
  }

  PopupSeparator { width: parent.width }

  // ---- controls --------------------------------------------------------------
  Column {
    width: parent.width
    spacing: 4

    PopupSelect {
      id: limit
      width: parent.width
      label: "CHARGE LIMIT"
      model: Theme.batteryLimits.map(v => ({ label: v + "%", value: v }))
      current: BatteryService.threshold
      busyValue: BatteryService.busy
      onPicked: value => BatteryService.setThreshold(value)
      onExpandedChanged: if (expanded) root.collapseOthers(limit)
    }

    PopupSelect {
      id: profile
      width: parent.width
      label: "POWER PROFILE"
      model: BatteryService.profiles.map(p => ({ label: p.toUpperCase(), value: p }))
      current: BatteryService.profile
      busyValue: BatteryService.busy
      onPicked: value => BatteryService.setProfile(value)
      onExpandedChanged: if (expanded) root.collapseOthers(profile)
    }

    PopupSelect {
      id: gpu
      width: parent.width
      visible: BatteryService.gpuMode !== ""
      label: "GPU"
      model: [
        { label: "INTEGRATED", value: "Integrated" },
        { label: "HYBRID",     value: "Hybrid" }
      ]
      current: BatteryService.gpuPending || BatteryService.gpuMode
      busyValue: BatteryService.busy
      onPicked: value => BatteryService.setGpuMode(value)
      onExpandedChanged: if (expanded) root.collapseOthers(gpu)
    }

    ThemeText {
      visible: BatteryService.gpuPending !== "" && BatteryService.gpuPending !== BatteryService.gpuMode
      text: "GPU: " + (BatteryService.gpuAction || "reboot required").toUpperCase()
      color: Theme.orange
      font.pixelSize: Theme.fontSize - 2
    }
  }

  PopupError { text: BatteryService.error }
}
