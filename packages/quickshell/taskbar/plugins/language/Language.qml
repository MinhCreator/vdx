import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.components
import qs.config

// Active keyboard layout as a short code. The initial value comes from
// `hyprctl devices` (Hyprland doesn't replay activelayout on connect), changes
// from the activelayout event.
Item {
  id: root

  property string layout: ""

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText {
    id: label
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    text: {
      const name = root.layout.toLowerCase();
      if (name.includes("english")) return Theme.languageFormatEn;
      if (name.includes("russian")) return Theme.languageFormatRu;
      return root.layout;
    }
    color: Theme.foreground1
  }

  Process {
    command: ["hyprctl", "devices", "-j"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          // Pseudo-keyboards (power buttons, WMI hotkeys) report a stale keymap:
          // prefer the main keyboard.
          const keyboards = JSON.parse(text).keyboards ?? [];
          const kb = keyboards.find(k => k.main && k.active_keymap) ?? keyboards.find(k => k.active_keymap);
          if (kb) root.layout = kb.active_keymap;
        } catch (e) {}
      }
    }
  }

  Connections {
    target: Hyprland
    // data: "<keyboard>,<layout name>"
    function onRawEvent(event) {
      if (event.name === "activelayout" && event.data)
        root.layout = event.data.slice(event.data.indexOf(",") + 1);
    }
  }
}
