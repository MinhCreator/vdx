import QtQuick
import qs.apps.capture
import qs.config
import qs.kit

// Capture options in the Shell Manager: what happens after a shot or a
// recording (save, ask where, or — for a shot — the clipboard only) and the
// default folders. A path applies on Enter; empty brings the default back.
Column {
  id: root

  spacing: 14

  KitOptionRow {
    plugin: "capture"; key: "shotTarget"; fallback: "folder"
    label: "After a screenshot"; hint: "it is always copied to the clipboard"
    model: [{ label: "Save", value: "folder" }, { label: "Ask where", value: "ask" }, { label: "Clipboard only", value: "clipboard" }]
  }

  KitOptionRow {
    plugin: "capture"; key: "videoTarget"; fallback: "folder"
    label: "After a recording"; hint: "Ask where: when you stop it"
    model: [{ label: "Save", value: "folder" }, { label: "Ask where", value: "ask" }]
  }

  KitLine {}

  Repeater {
    model: [
      { key: "shotDir",  label: "Screenshots", value: CaptureService.shotDir },
      { key: "videoDir", label: "Recordings",  value: CaptureService.videoDir }
    ]

    KitRow {
      id: row

      required property var modelData

      label: modelData.label
      hint: "press Enter to apply"

      KitInput {
        width: 260
        text: row.modelData.value
        onAccepted: PluginSettings.set("capture", row.modelData.key, text.trim().replace(/\/+$/, ""))
      }
    }
  }
}
