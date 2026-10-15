import QtQuick
import qs.apps.capture
import qs.config
import qs.kit

// Capture options in the Shell Manager, as full-width groups (the pane is too
// narrow for label-left rows): what happens after a screenshot and after a
// recording, then the default folders. A path applies on Enter; empty brings
// the default back.
Column {
  id: root

  spacing: 14

  Repeater {
    model: [
      { key: "shotTarget", title: "AFTER A SCREENSHOT",
        note: "It is always copied to the clipboard as well.",
        items: [{ label: "Save", value: "folder", icon: "folder" }, { label: "Ask where", value: "ask", icon: "list" },
                { label: "Clipboard", value: "clipboard", icon: "clipboard" }] },
      { key: "videoTarget", title: "AFTER A RECORDING",
        note: "Ask where opens when you stop; Esc keeps it in the folder below.",
        items: [{ label: "Save", value: "folder", icon: "folder" }, { label: "Ask where", value: "ask", icon: "list" }] }
    ]

    Column {
      id: group

      required property var modelData

      width: root.width
      spacing: 8

      KitLabel { text: group.modelData.title }

      KitChoices {
        width: parent.width
        stretch: true
        model: group.modelData.items
        current: PluginSettings.get("capture", group.modelData.key, "folder")
        onPicked: value => PluginSettings.set("capture", group.modelData.key, value)
      }

      KitText {
        width: parent.width
        text: group.modelData.note
        color: Theme.muted
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSize - 2
      }
    }
  }

  KitLine {}

  KitLabel { text: "FOLDERS"; value: "ENTER TO APPLY" }

  Repeater {
    model: [
      { key: "shotDir",  label: "Screenshots", value: CaptureService.shotDir },
      { key: "videoDir", label: "Recordings",  value: CaptureService.videoDir }
    ]

    Column {
      id: folder

      required property var modelData

      width: root.width
      spacing: 6

      KitText {
        text: folder.modelData.label
        font.pixelSize: Theme.fontSize - 1
      }

      KitInput {
        width: parent.width
        text: folder.modelData.value
        onAccepted: PluginSettings.set("capture", folder.modelData.key, text.trim().replace(/\/+$/, ""))
      }
    }
  }
}
