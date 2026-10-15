pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Options of each module, set in the Shell Manager's Modules section and kept
// in the state dir (modules.json): {"<module>": {"<key>": value}}. A module
// reads `get("sysmon", "gpu", true)` — the default lives with the module.
Singleton {
  id: root

  readonly property var values: state.values

  function get(module, key, fallback) {
    const v = values[module]?.[key];
    return v === undefined ? fallback : v;
  }

  function changed(module) { return Object.keys(values[module] ?? {}).length > 0; }

  // back to the module's defaults
  function reset(module) {
    const all = Object.assign({}, values);
    delete all[module];
    state.values = all;
  }

  function set(module, key, value) {
    const all = Object.assign({}, values);
    all[module] = Object.assign({}, all[module] ?? {}, { [key]: value });
    state.values = all;
  }

  FileView {
    path: Quickshell.statePath("modules.json")
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
