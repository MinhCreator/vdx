import QtQuick
import qs.config

// Hairline between groups. layer.enabled keeps it one device pixel thick on
// fractional scales.
Rectangle {
  readonly property bool isKitLine: true    // KitGrouper: ends a group
  width: parent ? parent.width : 0
  implicitHeight: 1
  color: Theme.divider
  layer.enabled: true
  layer.smooth: false
}
