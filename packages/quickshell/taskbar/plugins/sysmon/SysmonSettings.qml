import QtQuick
import qs.config
import qs.kit

// Sysmon options in the Shell Manager: the bar's text and which popup
// sections show.
Column {
  spacing: 14

  KitLabel { text: "BAR TEXT" }

  KitToggleRow {
    plugin: "sysmon"; key: "barPercent"
    label: "CPU load in the bar"
    hint: "off: the icon alone"
  }

  KitLine {}

  KitLabel { text: "POPUP SECTIONS" }

  KitToggleRow { plugin: "sysmon"; key: "cores";   label: "CPU cores";  hint: "a bar per core under the load" }
  KitToggleRow { plugin: "sysmon"; key: "memory";  label: "Memory";     hint: "used, total, swap" }
  KitToggleRow { plugin: "sysmon"; key: "gpu";     label: "GPU";        hint: "Intel clock, NVIDIA load and memory" }
  KitToggleRow { plugin: "sysmon"; key: "disks";   label: "Disks";      hint: "read / write, each partition" }
  KitToggleRow { plugin: "sysmon"; key: "network"; label: "Network";    hint: "down / up speed" }
  KitToggleRow { plugin: "sysmon"; key: "sensors"; label: "Sensors";    hint: "NVMe and Wi-Fi heat, fans" }
}
