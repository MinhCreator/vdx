import QtQuick
import qs.config
import qs.kit

// Sysmon options in the Shell Manager: which metrics the bar shows (in this
// order) and which popup sections show.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }

  KitToggleRow {
    module: "sysmon"; key: "barPercent"
    label: "Show CPU load"
    hint: "Off: icon only"
  }

  KitToggleRow { module: "sysmon"; key: "barMemory";  fallback: false; label: "Show memory";        hint: "Used, in percent" }
  KitToggleRow { module: "sysmon"; key: "barTemp";    fallback: false; label: "Show temperature";   hint: "CPU sensor" }
  KitToggleRow { module: "sysmon"; key: "barGpu";     fallback: false; label: "Show GPU load";      hint: "NVIDIA, while awake" }
  KitToggleRow { module: "sysmon"; key: "barNetwork"; fallback: false; label: "Show network speed"; hint: "Down and up" }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitToggleRow { module: "sysmon"; key: "cores";   label: "CPU cores";  hint: "A bar per core under the load" }
  KitToggleRow { module: "sysmon"; key: "memory";  label: "Memory";     hint: "Used, total, swap" }
  KitToggleRow { module: "sysmon"; key: "gpu";     label: "GPU";        hint: "Intel clock, NVIDIA load and memory" }
  KitToggleRow { module: "sysmon"; key: "disks";   label: "Disks";      hint: "Read / write, each partition" }
  KitToggleRow { module: "sysmon"; key: "network"; label: "Network";    hint: "Down / up speed" }
  KitToggleRow { module: "sysmon"; key: "sensors"; label: "Sensors";    hint: "NVMe and Wi-Fi heat, fans" }
}
