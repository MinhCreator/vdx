pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Options of each plugin, set in the Shell Manager's Plugins section and kept
// in the state dir (plugins.json): {"<plugin>": {"<key>": value}}. A plugin
// reads `get("sysmon", "gpu", true)` — the default lives with the plugin.
Singleton {
  id: root

  readonly property var values: state.values

  function get(plugin, key, fallback) {
    const v = values[plugin]?.[key];
    return v === undefined ? fallback : v;
  }

  function changed(plugin) { return Object.keys(values[plugin] ?? {}).length > 0; }

  // back to the plugin's defaults
  function reset(plugin) {
    const all = Object.assign({}, values);
    delete all[plugin];
    state.values = all;
  }

  function set(plugin, key, value) {
    const all = Object.assign({}, values);
    all[plugin] = Object.assign({}, all[plugin] ?? {}, { [key]: value });
    state.values = all;
  }

  FileView {
    path: Quickshell.statePath("plugins.json")
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: writeAdapter()

    JsonAdapter {
      id: state
      property var values: ({})
    }
  }
}
