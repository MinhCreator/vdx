import QtQuick
import qs.bar
import qs.config
import qs.kit

// Mode options in the Shell Manager: the bar face's text (Content: Light / Dark).
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "mode" }

  KitGrouper {}
}
