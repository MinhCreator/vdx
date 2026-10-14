import QtQuick
import qs.kit

// Device row: the kind on the left, the default device in a select box.
KitSelect {
  id: root

  property var nodes: []

  signal selected(var node)

  model: nodes.map(n => ({ label: AudioService.deviceName(n, nodes), value: n }))
  disabled: nodes.length === 0
  onPicked: value => root.selected(value)
}
