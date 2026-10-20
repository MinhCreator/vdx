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
  readonly property bool changed: ModuleSettings.changed("lock") || ShellSettings.changed(["passwordDots"])
  function reset() { ModuleSettings.reset("lock"); ShellSettings.reset(["passwordDots"]); }

  LockSettings { width: parent.width }

  // how a typed password shows: here and in every password field of the shell
  KitLabel { text: "PASSWORD" }

  KitRow {
    wide: true
    label: "Typed characters"
    hint: "Also in Wi-Fi and other fields"

    KitSegments {
      model: [{ label: "Dots", value: true }, { label: "Squares", value: false }]
      current: ShellSettings.passwordDots
      onPicked: value => ShellSettings.set("passwordDots", value)
    }
  }

  KitGrouper {}
}
