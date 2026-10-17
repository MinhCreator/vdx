import QtQuick
import qs.apps.capture
import qs.config
import qs.kit

// Capture options in the Shell Manager: what happens after a screenshot and
// after a recording, then the default folders. A path applies on Enter;
// empty brings the default back.
Column {
  id: root
  spacing: Theme.gapGroup

  KitLabel { text: "SAVING" }

  KitOptionRow {
    module: "capture"; key: "shotTarget"; fallback: "folder"
    label: "After a screenshot"; hint: "Also copied to the clipboard"
    model: [{ label: "Save", value: "folder", icon: "folder" }, { label: "Ask", value: "ask", icon: "list" },
            { label: "Clipboard", value: "clipboard", icon: "clipboard" }]
  }

  KitOptionRow {
    module: "capture"; key: "videoTarget"; fallback: "folder"
    label: "After a recording"; hint: "Ask: Esc saves to folder"
    model: [{ label: "Save", value: "folder", icon: "folder" }, { label: "Ask", value: "ask", icon: "list" }]
  }

  KitLine {}

  KitLabel { text: "FOLDERS" }

  Repeater {
    model: [
      { key: "shotDir",  label: "Screenshots", value: CaptureService.shotDir },
      { key: "videoDir", label: "Recordings",  value: CaptureService.videoDir }
    ]

    KitRow {
      required property var modelData

      label: modelData.label
      hint: "Enter applies; empty: default"
      wide: true

      KitInput {
        text: modelData.value
        onAccepted: ModuleSettings.set("capture", modelData.key, text.trim().replace(/\/+$/, ""))
      }
    }
  }
}
