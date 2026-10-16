import QtQuick
import qs.config
import qs.kit

// System metrics, read only: CPU (all cores and each), memory, GPUs, disks,
// network, temperatures and fans. Levels turn yellow / red as they fill up.
KitFrame {
  id: root

  function heat(t) { return t === null || t === undefined ? Theme.muted : t >= 85 ? Theme.red : t >= 70 ? Theme.yellow : Theme.foreground2; }
  function gb(bytes) { return (bytes / 1073741824).toFixed(1); }
  function duration(s) {
    const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60);
    return (d > 0 ? d + "d " : "") + (d > 0 || h > 0 ? h + "h " : "") + m + "m";
  }

  function on(key) { return ModuleSettings.get("sysmon", key, true); }

  readonly property real memPercent: SysmonService.mem.total > 0 ? 100 * SysmonService.memUsed / SysmonService.mem.total : 0
  readonly property var dgpu: SysmonService.dgpu

  // ---- header ----
  KitHeader {
    icon: "cpu"
    title: "System"
    subtitle: "UP " + root.duration(SysmonService.uptime).toUpperCase()
      + " · LOAD " + SysmonService.load.map(l => Number(l).toFixed(2)).join(" ")
  }

  KitLine {}

  // ---- cpu ----
  Column {
    width: parent.width
    spacing: 8

    KitLabel {
      text: "CPU"
      value: SysmonService.cpu + "% · " + (SysmonService.freq / 1000).toFixed(1) + " GHz"
        + (SysmonService.temps.cpu !== null ? " · " + SysmonService.temps.cpu + "°" : "")
      valueColor: Theme.loadColor(SysmonService.cpu)
    }

    KitBar { value: SysmonService.cpu / 100; tint: Theme.loadColor(SysmonService.cpu) }

    // each core: a thin bar, side by side
    Row {
      visible: root.on("cores")
      width: parent.width
      spacing: 4

      Repeater {
        model: SysmonService.cores

        KitBar {
          required property int modelData
          width: (parent.width - 4 * (SysmonService.cores.length - 1)) / Math.max(1, SysmonService.cores.length)
          value: modelData / 100
          tint: Theme.loadColor(modelData)
        }
      }
    }
  }

  KitLine { visible: root.on("memory") }

  // ---- memory ----
  Column {
    visible: root.on("memory")
    width: parent.width
    spacing: 8

    KitLabel {
      text: "MEMORY"
      value: root.gb(SysmonService.memUsed) + " / " + root.gb(SysmonService.mem.total) + " GB"
      valueColor: Theme.loadColor(root.memPercent)
    }

    KitBar { value: root.memPercent / 100; tint: Theme.loadColor(root.memPercent) }

    KitInfo {
      visible: SysmonService.mem.swapTotal > 0
      label: "Swap"
      value: root.gb(SysmonService.swapUsed) + " / " + root.gb(SysmonService.mem.swapTotal) + " GB"
    }
  }

  KitLine { visible: root.on("gpu") }

  // ---- gpu ----
  Column {
    visible: root.on("gpu")
    width: parent.width
    spacing: 8

    KitLabel { text: "GPU" }

    KitInfo {
      visible: SysmonService.igpu !== null
      label: "Intel"
      value: SysmonService.igpu ? SysmonService.igpu.cur + " / " + SysmonService.igpu.max + " MHz" : ""
    }

    KitInfo {
      visible: root.dgpu.state !== "none"
      label: root.dgpu.state === "active" ? root.dgpu.name.replace(/^NVIDIA (GeForce )?/, "").replace(/ Laptop GPU$/, "") : "NVIDIA"
      value: root.dgpu.state === "active" ? root.dgpu.util + "%" : "asleep"
      valueColor: root.dgpu.state === "active" ? Theme.loadColor(root.dgpu.util) : Theme.muted
    }

    KitBar {
      visible: root.dgpu.state === "active"
      value: (root.dgpu.util ?? 0) / 100
      tint: Theme.loadColor(root.dgpu.util ?? 0)
    }

    KitInfo {
      visible: root.dgpu.state === "active"
      label: "VRAM"
      value: (root.dgpu.memUsed ?? 0) + " / " + (root.dgpu.memTotal ?? 0) + " MiB"
    }

    KitInfo {
      visible: root.dgpu.state === "active" && (root.dgpu.temp !== null || root.dgpu.power !== null)
      label: "Heat · power"
      value: (root.dgpu.temp !== null ? root.dgpu.temp + "°" : "--") + " · " + (root.dgpu.power !== null ? Math.round(root.dgpu.power) + " W" : "--")
      valueColor: root.heat(root.dgpu.temp)
    }
  }

  KitLine { visible: root.on("disks") }

  // ---- disks ----
  Column {
    visible: root.on("disks")
    width: parent.width
    spacing: 8

    KitLabel {
      text: "DISKS"
      value: "R " + Theme.humanRate(SysmonService.readRate) + " · W " + Theme.humanRate(SysmonService.writeRate)
    }

    Repeater {
      model: SysmonService.disks

      Column {
        id: disk

        required property var modelData

        readonly property real percent: modelData.size > 0 ? 100 * modelData.used / modelData.size : 0

        width: parent.width
        spacing: 5

        KitInfo {
          label: disk.modelData.mount
          value: Theme.humanSize(disk.modelData.used) + " / " + Theme.humanSize(disk.modelData.size)
          valueColor: Theme.loadColor(disk.percent)
        }

        KitBar { value: disk.percent / 100; tint: Theme.loadColor(disk.percent) }
      }
    }
  }

  KitLine { visible: root.on("network") }

  // ---- network, sensors ----
  Column {
    visible: root.on("network")
    width: parent.width
    spacing: 6

    KitLabel { text: "NETWORK"; value: SysmonService.iface.toUpperCase() }

    KitInfo {
      label: "Down · up"
      value: Theme.humanRate(SysmonService.rxRate) + " · " + Theme.humanRate(SysmonService.txRate)
    }
  }

  KitLine { visible: root.on("sensors") }

  Column {
    visible: root.on("sensors")
    width: parent.width
    spacing: 6

    KitLabel { text: "SENSORS" }

    KitInfo {
      visible: SysmonService.temps.nvme.length > 0
      label: "NVMe"
      value: SysmonService.temps.nvme.map(t => t + "°").join(" · ")
      valueColor: root.heat(Math.max(...SysmonService.temps.nvme))
    }

    KitInfo {
      visible: SysmonService.temps.wifi !== null
      label: "Wi-Fi"
      value: SysmonService.temps.wifi + "°"
      valueColor: root.heat(SysmonService.temps.wifi)
    }

    KitInfo {
      visible: SysmonService.fans.length > 0
      label: "Fans"
      value: SysmonService.fans.join(" · ") + " rpm"
    }
  }
}
