import QtQuick
import qs.config

// Hairline between groups. layer.enabled keeps it one device pixel thick on
// fractional scales.
Rectangle {
  width: parent ? parent.width : 0
  implicitHeight: 1
  color: Theme.background3
  layer.enabled: true
  layer.smooth: false
}
