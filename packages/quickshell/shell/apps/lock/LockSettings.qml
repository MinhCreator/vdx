import QtQuick
import Quickshell
import qs.config
import qs.kit

// Lock screen options in Shell apps (ModuleSettings "lock"): what the lock
// (Super+Z) shows — the background, the clock, the blur, the date, the user and
// the monitors it shows on; then the controls on it: the keyboard layout, the
// power buttons and the cursor that hides after a few still seconds (apps/lock
// reads them).
Column {
  id: root

  function opt(key, fallback) { return ModuleSettings.get("lock", key, fallback); }

  spacing: 14

  // ---- look ----
  KitLabel { text: "LOOK" }

  KitOptionRow {
    module: "lock"; key: "background"; fallback: "solid"
    label: "Background"; hint: "Blurred: the desktop as it was"
    model: [{ label: "Solid", value: "solid" }, { label: "Wallpaper", value: "wallpaper" }, { label: "Blurred", value: "blur" }]
  }

  KitRow {
    visible: root.opt("background", "solid") === "blur"
    wide: true
    label: "Blur"; hint: "How soft the desktop gets"

    Item {
      id: blurBox
      // the reading follows the knob while it is dragged; saved on release
      readonly property int percent: Math.round((blurSlider.pressed ? blurSlider.shown : root.opt("blur", 60) / 100) * 100)
      height: 20

      KitSlider {
        id: blurSlider
        anchors { left: parent.left; right: blurValue.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
        value: root.opt("blur", 60) / 100
        onMoved: v => { if (!pressed) ModuleSettings.set("lock", "blur", Math.round(v * 100)); }
        onReleased: v => ModuleSettings.set("lock", "blur", Math.round(v * 100))
      }

      KitText {
        id: blurValue
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        width: 40
        horizontalAlignment: Text.AlignRight
        text: blurBox.percent + "%"
        color: Theme.foreground2
      }
    }
  }

  KitOptionRow {
    module: "lock"; key: "clock"; fallback: "24h"
    label: "Clock"; hint: "The time's format"
    model: [{ label: "24h", value: "24h" }, { label: "12h", value: "12h" }]
  }

  KitToggleRow { module: "lock"; key: "date"; fallback: true; label: "Date"; hint: "The day under the time" }

  KitToggleRow { module: "lock"; key: "user"; fallback: true; label: "User"; hint: "Who is signed in" }

  // other monitors stay dark; typing there still goes into the password
  KitOptionRow {
    module: "lock"; key: "screen"; fallback: "all"
    label: "Monitors"; hint: "Focused: the one in use when it locks"
    model: [{ label: "All", value: "all" }, { label: "Focused", value: "focused" }]
           .concat(Quickshell.screens.map(s => ({ label: s.name, value: s.name })))
  }

  KitLine {}

  // ---- controls ----
  KitLabel { text: "CONTROLS" }

  KitToggleRow { module: "lock"; key: "layout"; fallback: true; label: "Keyboard layout"; hint: "Beside the field, a click switches it" }

  KitToggleRow { module: "lock"; key: "power"; fallback: true; label: "Power buttons"; hint: "Suspend, reboot, shut down" }

  KitToggleRow { module: "lock"; key: "hideCursor"; fallback: true; label: "Hide cursor when idle"; hint: "Shows again when the mouse moves" }

  KitOptionRow {
    visible: root.opt("hideCursor", true)
    module: "lock"; key: "cursorDelay"; fallback: 3
    label: "Hide after"; hint: "Seconds without a mouse move"
    model: [1, 3, 5, 10].map(v => ({ label: v + " s", value: v }))
  }

  KitLine {}

  KitRow {
    label: "Try it"
    hint: "Locks the screen now"

    KitButton {
      icon: "lock"
      text: "Lock"
      onClicked: Quickshell.execDetached(["qs", "-c", "shell", "ipc", "call", "lock", "lock"])
    }
  }
}
