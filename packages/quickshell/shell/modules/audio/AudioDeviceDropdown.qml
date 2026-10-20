import QtQuick
import qs.kit

// The device: a select box across the popup (device names are long; its note is
// the group's caption). `entries` come from AudioService.outputs / inputs.
KitSelect {
  id: root

  property var entries: []

  boxWidth: width

  model: entries.map(e => ({ label: e.label, value: e.key }))
  disabled: entries.length === 0
  onPicked: value => AudioService.select(entries.find(e => e.key === value))
}
