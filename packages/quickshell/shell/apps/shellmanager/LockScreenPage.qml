import QtQuick
import qs.apps.keybinds
import qs.apps.lock
import qs.config
import qs.kit

// Lock screen: the lock's own options (apps/lock/LockSettings.qml, values in
// ModuleSettings "lock"); Reset in the window's header brings the defaults back.
// It was an app under Apps until 05; `shell open lock` still opens it.
Column {
  id: root

  // the window's fixed header shows these; the page under it scrolls
  readonly property string icon: "lock"
  readonly property string title: "Lock screen"
  readonly property string subtitle: (KeybindsService.keysFor("Lock the screen").join(" + ") || "LOCK").toUpperCase()
  readonly property var jumps: []

  // the header's Reset
  readonly property bool changed: ModuleSettings.changed("lock")
  function reset() { ModuleSettings.reset("lock"); }

  LockSettings { width: parent.width }
}
