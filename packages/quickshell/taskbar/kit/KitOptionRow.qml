import QtQuick
import qs.config

// A settings row with choices bound to one plugin option (PluginSettings):
// `plugin`, `key`, `fallback` (the default), `model` [{label, value}].
KitRow {
  id: root

  wide: true

  property string plugin
  property string key
  property var fallback
  property var model: []

  KitChoices {
    stretch: true
    model: root.model
    current: PluginSettings.get(root.plugin, root.key, root.fallback)
    onPicked: value => PluginSettings.set(root.plugin, root.key, value)
  }
}
