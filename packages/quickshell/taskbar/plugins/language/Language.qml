import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config

// hyprland/language (packages/waybar/modules/language.jsonc + styles/language.css):
//   format "{}" · format-en "US" · format-ru "RU" · color foreground1
//   margin-right 20px.
//
// waybar listens to Hyprland's `activelayout` event and resolves the xkb layout
// *brief* description ("English (US)" -> "en", "Russian" -> "ru") before looking
// up `format-en`/`format-ru`. We map the same full names to the same output.
// See waybar src/modules/hyprland/language.cpp (getLayout/short_description).
//
// Initial value comes from `hyprctl devices -j` (Hyprland does not emit the
// activelayout event on connect); live changes come from Hyprland.rawEvent.

Item {
  id: root

  property string activeLayout: ""

  readonly property string labelText: {
    const k = root.activeLayout.toLowerCase()
    if (k.indexOf("english") >= 0) return Theme.languageFormatEn
    if (k.indexOf("russian") >= 0) return Theme.languageFormatRu
    // waybar falls back to the raw layout name when no format-<lang> matches.
    return root.activeLayout
  }

  Text {
    id: label
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    text: root.labelText
    color: Theme.foreground1
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  // extra width on the right == margin-right: 20px
  implicitWidth: label.implicitWidth + Theme.edgeMargin
  implicitHeight: label.implicitHeight

  // initial layout: waybar's initLanguage reads the first keymap from `devices`.
  Process {
    id: devicesProc
    command: ["hyprctl", "devices", "-j"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const data = JSON.parse(this.text.trim())
          const keyboards = data.keyboards || []
          // `hyprctl devices` lists pseudo-keyboards for power/sleep buttons and
          // WMI hotkeys; their `active_keymap` is stale ("English (US)") even
          // when the real layout is Russian. Use the device Hyprland marks as
          // `main`, and only fall back to the first entry that reports a keymap.
          const main = keyboards.find(kb => kb.main && kb.active_keymap)
          if (main) {
            root.activeLayout = main.active_keymap
          } else {
            for (const kb of keyboards) {
              if (kb.active_keymap) {
                root.activeLayout = kb.active_keymap
                break
              }
            }
          }
        } catch (e) {
          // leave the label empty until a live event arrives
        }
      }
    }
  }

  Connections {
    target: Hyprland

    function onRawEvent(event) {
      // data = "<keyboard>,<xkb layout name>", e.g. "some-kbd,English (US)".
      if (event.name === "activelayout" && event.data) {
        const comma = event.data.indexOf(",")
        root.activeLayout = comma >= 0
            ? event.data.substring(comma + 1)
            : event.data
      }
    }
  }
}
