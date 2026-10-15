import QtQuick
import qs.kit

// Device row: the kind on the left, the default device and port in a select
// box. `entries` come from AudioService.outputs / inputs.
KitSelect {
  id: root

  property var entries: []

  model: entries.map(e => ({ label: e.label, value: e.key }))
  disabled: entries.length === 0
  onPicked: value => AudioService.select(entries.find(e => e.key === value))
}
