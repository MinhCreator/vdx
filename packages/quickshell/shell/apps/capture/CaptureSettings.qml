import QtQuick
import qs.apps.files
import qs.config
import qs.kit

// Capture's app options in the Shell Manager: how the shortcut opens it, where
// screenshots and recordings go, the codec and what it can cost. The popup and
// the bar face are the module's (Apps › Bar module).
Column {
  spacing: Theme.gapGroup

  KitLabel { text: "SHORTCUT" }

  KitOptionRow {
    module: "capture"; key: "shortcut"; fallback: "popup"
    label: "Shortcut opens"
    hint: "No module: the bar's centre"
    model: [{ label: "Popup", value: "popup" }, { label: "Else last", value: "else-last" }, { label: "Last mode", value: "last" }]
  }

  KitLine {}

  KitLabel { text: "SAVING" }

  KitOptionRow {
    module: "capture"; key: "shotTarget"; fallback: "folder"
    label: "After a screenshot"; hint: "Also copied to the clipboard"
    model: [{ label: "Save", value: "folder" }, { label: "Ask", value: "ask" }, { label: "Clipboard", value: "clipboard" }]
  }

  KitOptionRow {
    module: "capture"; key: "videoTarget"; fallback: "folder"
    label: "After a recording"; hint: "Ask: Esc saves to folder"
    model: [{ label: "Save", value: "folder" }, { label: "Ask", value: "ask" }]
  }

  KitLine {}

  KitLabel { text: "RECORDING" }

  KitOptionRow {
    module: "capture"; key: "quality"; fallback: "medium"
    label: "Quality"
    hint: "Low tints flat greys"
    model: [{ label: "Low", value: "low" }, { label: "Medium", value: "medium" }, { label: "High", value: "high" }]
  }

  KitOptionRow {
    module: "capture"; key: "fps"; fallback: 60
    label: "Frame rate"
    model: [{ label: "30 fps", value: 30 }, { label: "60 fps", value: 60 }]
  }

  KitOptionRow {
    module: "capture"; key: "codec"; fallback: "auto"
    label: "Codec"
    hint: "Auto: HEVC on the GPU"
    model: [{ label: "Auto", value: "auto" }, { label: "H.264", value: "h264" }, { label: "HEVC", value: "hevc" }]
  }

  KitOptionRow {
    module: "capture"; key: "encoder"; fallback: "auto"
    label: "Encoder"
    hint: "Auto: iGPU on battery"
    model: [{ label: "Auto", value: "auto" }, { label: "iGPU", value: "igpu" }, { label: "GPU", value: "gpu" }, { label: "CPU", value: "cpu" }]
  }

  // every problem the current codec, encoder and quality can cause
  KitLabel { text: "PROBLEMS"; value: CaptureService.codecIssues.length === 0 ? "NONE" : "" }

  Repeater {
    model: CaptureService.codecIssues

    Column {
      required property var modelData

      width: parent.width
      spacing: Theme.gapHair

      KitText {
        width: parent.width
        wrapMode: Text.WordWrap
        font.weight: Font.ExtraBold
        color: modelData.warn ? Theme.yellow : Theme.foreground0
        text: modelData.title
      }

      KitText {
        width: parent.width
        wrapMode: Text.WordWrap
        color: modelData.warn ? Theme.yellow : Theme.muted
        text: modelData.text
      }
    }
  }

  KitLine {}

  KitLabel { text: "NOTIFICATIONS" }

  KitToggleRow { module: "capture"; key: "notifyShot"; fallback: true; label: "Notify after a screenshot"; hint: "Errors still notify" }
  KitToggleRow { module: "capture"; key: "notifyRecord"; fallback: true; label: "Notify after a recording"; hint: "Errors still notify" }

  KitLinkRow {
    label: "Toasts"
    hint: "How long, the history: Notifications"
    target: "notifications"
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

      Row {
        spacing: Theme.gapMedium

        KitInput {
          width: parent.width - chooseDir.width - parent.spacing
          text: modelData.value
          onAccepted: ModuleSettings.set("capture", modelData.key, text.trim().replace(/\/+$/, ""))
        }

        KitButton {
          id: chooseDir
          icon: "folder"
          text: "Choose…"
          onClicked: FilesService.pickFolder(modelData.label + " folder", modelData.value,
                                             p => { if (p !== "") ModuleSettings.set("capture", modelData.key, p); })
        }
      }
    }
  }
}
