import QtQuick
import qs.bar
import qs.config
import qs.kit

// The display's bar module options (Shell apps › BAR): the scale of its monitor
// or the module's name.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "display" }
}
