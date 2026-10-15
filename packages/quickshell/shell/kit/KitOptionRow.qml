import QtQuick
import qs.config

// A settings row with choices bound to one module option (ModuleSettings):
// `module`, `key`, `fallback` (the default), `model` [{label, value}].
KitRow {
  id: root

  wide: true

  property string module
  property string key
  property var fallback
  property var model: []

  KitChoices {
    stretch: true
    model: root.model
    current: ModuleSettings.get(root.module, root.key, root.fallback)
    onPicked: value => ModuleSettings.set(root.module, root.key, value)
  }
}
