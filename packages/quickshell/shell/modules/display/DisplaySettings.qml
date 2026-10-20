import QtQuick
import qs.bar
import qs.config
import qs.kit

// The display module's options (Bar modules › Display): the scale of its
// monitor or the module's name. The monitors themselves: Shell Manager › Displays.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "display" }

  KitGrouper {}
}
