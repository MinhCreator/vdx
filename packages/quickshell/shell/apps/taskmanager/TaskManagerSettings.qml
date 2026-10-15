import QtQuick
import qs.config
import qs.kit

// Task manager options in the Shell Manager (ModuleSettings "taskmanager"):
// what the list shows and how, then ending. The bar module's own row is
// TaskManagerBarSettings (Shell apps › BAR).
Column {
  spacing: 14

  KitLabel { text: "LIST" }

  KitToggleRow { module: "taskmanager"; key: "group"; label: "Group by program"; hint: "One row per program, its processes summed" }
  KitToggleRow { module: "taskmanager"; key: "onlyMine"; fallback: false; label: "Only my processes"; hint: "Off: root's and the system's too" }
  KitToggleRow { module: "taskmanager"; key: "kernel"; fallback: false; label: "Kernel threads"; hint: "Kworkers and the like" }

  KitOptionRow {
    module: "taskmanager"; key: "sortBy"; fallback: "cpu"
    label: "Sort by"; hint: "Also a click on a column title"
    model: [{ label: "CPU", value: "cpu" }, { label: "Memory", value: "mem" }, { label: "Name", value: "name" }]
  }

  KitOptionRow {
    module: "taskmanager"; key: "refresh"; fallback: 2
    label: "Refresh"; hint: "Seconds, while the window is open"
    model: [{ label: "1", value: 1 }, { label: "2", value: 2 }, { label: "5", value: 5 }]
  }

  KitLine {}

  KitLabel { text: "ENDING" }

  KitToggleRow { module: "taskmanager"; key: "confirm"; label: "Ask before ending"; hint: "End / Kill asks “Sure?” once" }
}
