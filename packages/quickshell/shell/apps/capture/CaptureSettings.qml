import QtQuick
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
    hint: "Without the module: the bar's centre"
    model: [{ label: "Popup", value: "popup" }, { label: "Else last", value: "else-last" }, { label: "Last mode", value: "last" }]
  }

  KitLine {}

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

  KitLabel { text: "RECORDING" }

  KitRow {
    label: "Codec"
    hint: "Auto: HEVC on the GPU"
    wide: true

    KitChoices {
      stretch: true
      model: [{ label: "Auto", value: "auto" }, { label: "H.264", value: "h264" }, { label: "HEVC", value: "hevc" }]
      current: CaptureService.codec
      onPicked: value => CaptureService.setCodec(value)
    }
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
