import QtQuick
import qs.config

// Horizontal popup divider. layer.enabled snaps the rect to whole device pixels,
// so every separator has the same thickness on fractional scales.
Rectangle {
  implicitHeight: 1.5
  color: Theme.dim
  layer.enabled: true
  layer.smooth: false
}
