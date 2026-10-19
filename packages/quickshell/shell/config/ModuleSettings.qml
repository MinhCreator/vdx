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

  // `keys` (optional): only those (an app and its bar module share one id:
  // config/settings-keys.json lists each one's)
  function changed(module, keys) {
    return Object.keys(values[module] ?? {}).some(k => !keys || keys.includes(k));
  }

  // back to the module's defaults
  function reset(module, keys) {
    const all = Object.assign({}, values);
    if (keys) {
      const left = Object.assign({}, all[module] ?? {});
      for (const k of keys) delete left[k];
      all[module] = left;
    } else {
      delete all[module];
    }
    state.values = all;
  }

  // the keys of each app's and app module's settings file (scripts/settings_index.py)
  property var fileKeys: ({})
  function keysOf(file) { return fileKeys[file] ?? null; }

  FileView {
    path: Quickshell.shellDir + "/config/settings-keys.json"
    printErrors: false
    onLoaded: { try { root.fileKeys = JSON.parse(text()); } catch (e) { root.fileKeys = {}; } }
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
      property int version: 0         // schema (scripts/settings_migrate.py stamps it)
      property var values: ({})
    }
  }
}
