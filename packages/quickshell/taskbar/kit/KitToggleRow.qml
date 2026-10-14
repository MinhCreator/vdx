import QtQuick
import qs.config

// A settings row with a switch bound to one plugin option (PluginSettings):
// `plugin`, `key`, `fallback` (the default), label and hint.
KitRow {
  id: root

  property string plugin
  property string key
  property bool fallback: true

  readonly property bool checked: PluginSettings.get(plugin, key, fallback)

  KitSwitch {
    checked: root.checked
    onToggled: PluginSettings.set(root.plugin, root.key, !root.checked)
  }
}
