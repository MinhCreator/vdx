import QtQuick
import qs.config
import qs.kit

// Sysmon options in the Shell Manager: the bar's text and which popup
// sections show.
Column {
  spacing: 14

  KitLabel { text: "BAR" }

  KitToggleRow {
    plugin: "sysmon"; key: "barPercent"
    label: "CPU load in the bar"
    hint: "Off: the icon alone"
  }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitToggleRow { plugin: "sysmon"; key: "cores";   label: "CPU cores";  hint: "A bar per core under the load" }
  KitToggleRow { plugin: "sysmon"; key: "memory";  label: "Memory";     hint: "Used, total, swap" }
  KitToggleRow { plugin: "sysmon"; key: "gpu";     label: "GPU";        hint: "Intel clock, NVIDIA load and memory" }
  KitToggleRow { plugin: "sysmon"; key: "disks";   label: "Disks";      hint: "Read / write, each partition" }
  KitToggleRow { plugin: "sysmon"; key: "network"; label: "Network";    hint: "Down / up speed" }
  KitToggleRow { plugin: "sysmon"; key: "sensors"; label: "Sensors";    hint: "NVMe and Wi-Fi heat, fans" }
}
