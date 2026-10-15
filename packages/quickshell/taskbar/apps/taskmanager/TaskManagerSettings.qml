import QtQuick
import qs.config
import qs.kit

// Task manager options in the Shell Manager (PluginSettings "taskmanager"):
// what the list shows and how, then ending.
Column {
  spacing: 14

  KitLabel { text: "LIST" }

  KitToggleRow { plugin: "taskmanager"; key: "group"; label: "Group by program"; hint: "one row per program, its processes summed" }
  KitToggleRow { plugin: "taskmanager"; key: "onlyMine"; fallback: false; label: "Only my processes"; hint: "off: root's and the system's too" }
  KitToggleRow { plugin: "taskmanager"; key: "kernel"; fallback: false; label: "Kernel threads"; hint: "kworkers and the like" }

  KitOptionRow {
    plugin: "taskmanager"; key: "sortBy"; fallback: "cpu"
    label: "Sort by"; hint: "also a click on a column title"
    model: [{ label: "CPU", value: "cpu" }, { label: "Memory", value: "mem" }, { label: "Name", value: "name" }]
  }

  KitOptionRow {
    plugin: "taskmanager"; key: "refresh"; fallback: 2
    label: "Refresh"; hint: "seconds, while the window is open"
    model: [{ label: "1", value: 1 }, { label: "2", value: 2 }, { label: "5", value: 5 }]
  }

  KitLine {}

  KitLabel { text: "POPUP" }

  KitOptionRow {
    plugin: "taskmanager"; key: "popupRows"; fallback: 5
    label: "Programs listed"; hint: "the busiest, in the bar's popup"
    model: [{ label: "3", value: 3 }, { label: "5", value: 5 }, { label: "8", value: 8 }]
  }

  KitLine {}

  KitLabel { text: "ENDING" }

  KitToggleRow { plugin: "taskmanager"; key: "confirm"; label: "Ask before ending"; hint: "End / Kill asks “Sure?” once" }
}
