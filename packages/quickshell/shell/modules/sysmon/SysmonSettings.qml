import QtQuick
import qs.bar
import qs.config
import qs.kit

// Sysmon options in the Shell Manager: which metrics the bar shows (in this
// order) and which popup sections show.
Column {
  spacing: Theme.sectionGap

  KitLabel { text: "BAR" }
  BarTextRow { id: barText; module: "sysmon" }

  KitToggleRow {
    visible: barText.content
    module: "sysmon"; key: "barPercent"
    label: "Show CPU load"
    hint: "Off: icon only"
  }

  KitToggleRow { visible: barText.content; module: "sysmon"; key: "barMemory";  fallback: false; label: "Show memory";        hint: "Used, in percent" }
  KitToggleRow { visible: barText.content; module: "sysmon"; key: "barTemp";    fallback: false; label: "Show temperature";   hint: "CPU sensor" }
  KitToggleRow { visible: barText.content; module: "sysmon"; key: "barGpu";     fallback: false; label: "Show GPU load";      hint: "NVIDIA, while awake" }
  KitToggleRow { visible: barText.content; module: "sysmon"; key: "barNetwork"; fallback: false; label: "Show network speed"; hint: "Down and up" }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitToggleRow { module: "sysmon"; key: "cores";   label: "Show CPU cores";  hint: "A bar per core under the load" }
  KitToggleRow { module: "sysmon"; key: "memory";  label: "Show memory";     hint: "Used, total, swap" }
  KitToggleRow { module: "sysmon"; key: "gpu";     label: "Show GPU";        hint: "Intel clock, NVIDIA load and memory" }
  KitToggleRow { module: "sysmon"; key: "disks";   label: "Show disks";      hint: "Read / write, each partition" }
  KitToggleRow { module: "sysmon"; key: "network"; label: "Show network";    hint: "Down / up speed" }
  KitToggleRow { module: "sysmon"; key: "sensors"; label: "Show sensors";    hint: "NVMe and Wi-Fi heat, fans" }

  KitGrouper {}
}
