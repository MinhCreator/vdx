import QtQuick
import qs.bar
import qs.config
import qs.kit

// Language options in the Shell Manager: the bar face's text.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "language" }
}
