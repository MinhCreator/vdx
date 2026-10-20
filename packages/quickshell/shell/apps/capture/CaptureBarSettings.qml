import QtQuick
import qs.bar
import qs.config
import qs.kit

// Capture's bar module options (Bar modules › Capture): the face only. A
// click is Super+Shift+S; the choices are the overlay's toolbar.
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "BAR" }
  BarTextRow { module: "capture" }

  KitGrouper {}
}
