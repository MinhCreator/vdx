import QtQuick
import qs.apps.capture
import qs.config
import qs.kit

// Capture options in the Shell Manager: where shots and recordings go. A path
// applies on Enter; empty brings the default back.
Column {
  id: root

  spacing: 14

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
