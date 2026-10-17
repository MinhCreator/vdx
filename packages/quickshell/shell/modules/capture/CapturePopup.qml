import QtQuick
import qs.config
import qs.kit

// The capture panel, in the popups' style: what (region / window / screen) and
// as (shot / recording) as full-width choice rows; where it goes; a recording's
// sound, frame rate, quality, codec and encoder (auto: integrated GPU on battery); the
// pointer. Start closes the panel and, once the bar is back, hands over to the
// selection on screen; a recording shows its time and stops here.
KitFrame {
  id: root

  property int elapsed: 0

  signal started()

  readonly property var labels: ({
    region: "REGION", window: "WINDOW", screen: "SCREEN", shot: "SHOT", record: "RECORDING"
  })

  function home(path) {
    const h = CaptureService.shotDir.split("/").slice(0, 3).join("/");
    return path.startsWith(h) ? "~" + path.slice(h.length) : path;
  }

  KitHeader {
    icon: CaptureService.kind === "record" ? "video" : "camera"
    title: "Capture"
    subtitle: CaptureService.recording
      ? "RECORDING · " + String(Math.floor(root.elapsed / 60)).padStart(2, "0") + ":" + String(root.elapsed % 60).padStart(2, "0")
      : root.labels[CaptureService.mode] + " · " + root.labels[CaptureService.kind]
        + (CaptureService.cursor ? " · CURSOR" : "")
  }

  KitLine {}

  // ---- a recording running: stop it here ----
  KitRow {
    visible: CaptureService.recording
    label: "Recording"
    hint: "Stop to save it"

    KitButton {
      icon: "square"
      text: "Stop"
      iconTint: Theme.red
      onClicked: CaptureService.stopRecording()
    }
  }

  // ---- what and how ----
  Column {
    visible: !CaptureService.recording
    width: parent.width
    spacing: Theme.gapGroup

    Column {
      width: parent.width
      spacing: Theme.gapMedium

      KitLabel { text: "WHAT" }

      KitChoices {
        width: parent.width
        stretch: true
        model: [
          { label: "Region", value: "region", icon: "crop" },
          { label: "Window", value: "window", icon: "app-window" },
          { label: "Screen", value: "screen", icon: "monitor" }
        ]
        current: CaptureService.mode
        onPicked: value => CaptureService.setMode(value)
      }
    }

    Column {
      width: parent.width
      spacing: Theme.gapMedium

      KitLabel { text: "AS" }

      KitChoices {
        width: parent.width
        stretch: true
        model: [
          { label: "Screenshot", value: "shot",   icon: "camera" },
          { label: "Recording",  value: "record", icon: "video" }
        ]
        current: CaptureService.kind
        onPicked: value => CaptureService.setKind(value)
      }
    }

    KitLine {}

    // ---- where it goes: a shot always reaches the clipboard ----
    Column {
      width: parent.width
      spacing: Theme.gapMedium

      KitLabel {
        text: "SAVE"
        value: CaptureService.kind === "shot"
          ? (CaptureService.shotTarget === "folder" ? root.home(CaptureService.shotDir).toUpperCase()
             : CaptureService.shotTarget === "ask" ? "ASKS WHERE" : "CLIPBOARD ONLY")
          : (CaptureService.videoTarget === "folder" ? root.home(CaptureService.videoDir).toUpperCase() : "ASKS WHERE")
      }

      KitChoices {
        width: parent.width
        stretch: true
        model: CaptureService.kind === "shot"
          ? [{ label: "Folder", value: "folder", icon: "folder" }, { label: "Ask", value: "ask", icon: "list" },
             { label: "Clipboard", value: "clipboard", icon: "clipboard" }]
          : [{ label: "Folder", value: "folder", icon: "folder" }, { label: "Ask", value: "ask", icon: "list" }]
        current: CaptureService.kind === "shot" ? CaptureService.shotTarget : CaptureService.videoTarget
        onPicked: value => ModuleSettings.set("capture", CaptureService.kind === "shot" ? "shotTarget" : "videoTarget", value)
      }
    }

    // ---- a recording: its settings ----
    Column {
      visible: CaptureService.kind === "record"
      width: parent.width
      spacing: Theme.gapWide

      Repeater {
        model: [
          { title: "SOUND", key: "audio", items: [{ label: "Off", value: "off", icon: "volume-x" },
                                                  { label: "System", value: "system", icon: "volume" },
                                                  { label: "Mic", value: "mic", icon: "mic" }] },
          { title: "FRAME RATE", key: "fps", items: [{ label: "30 fps", value: 30 }, { label: "60 fps", value: 60 }] },
          { title: "QUALITY", key: "quality", items: [{ label: "Low", value: "low" }, { label: "Medium", value: "medium" },
                                                      { label: "High", value: "high" }] },
          { title: "CODEC", key: "codec", items: [{ label: "Auto", value: "auto" }, { label: "H.264", value: "h264" },
                                                  { label: "HEVC", value: "hevc" }] },
          { title: "ENCODER", key: "encoder", items: [{ label: "Auto", value: "auto" }, { label: "iGPU", value: "igpu" },
                                                      { label: "GPU", value: "gpu" }, { label: "CPU", value: "cpu" }] }
        ]

        Column {
          id: setting

          required property var modelData

          width: parent.width
          spacing: Theme.gapMedium

          KitLabel {
            text: setting.modelData.title
            value: setting.modelData.key === "encoder" && CaptureService.encoder === "auto"
              ? (CaptureService.encoderInUse === "igpu" ? "IGPU NOW · ON BATTERY" : "GPU NOW · ON POWER")
              : setting.modelData.key === "codec" && CaptureService.codec === "auto"
              ? (CaptureService.codecInUse === "hevc" ? "HEVC NOW" : "H.264 NOW") : ""
          }

          KitChoices {
            width: parent.width
            stretch: true
            model: setting.modelData.items
            current: ({ audio: CaptureService.audio, fps: CaptureService.fps, quality: CaptureService.quality,
                        codec: CaptureService.codec, encoder: CaptureService.encoder })[setting.modelData.key]
            onPicked: value => {
              const key = setting.modelData.key;
              if (key === "audio") CaptureService.setAudio(value);
              else if (key === "fps") CaptureService.setFps(value);
              else if (key === "quality") CaptureService.setQuality(value);
              else if (key === "codec") CaptureService.setCodec(value);
              else CaptureService.setEncoder(value);
            }
          }
        }
      }

      // what the codec does to this recording: a warning in yellow, a note in grey
      KitText {
        visible: CaptureService.codecNote.text !== ""
        width: parent.width
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSize - 2
        color: CaptureService.codecNote.warn ? Theme.yellow : Theme.muted
        text: CaptureService.codecNote.text
      }
    }

    KitLine {}

    KitRow {
      label: "Hide cursor"
      hint: "Keep the pointer out of the picture"

      KitSwitch {
        checked: !CaptureService.cursor
        onToggled: CaptureService.setCursor(!CaptureService.cursor)
      }
    }

    KitButton {
      width: parent.width
      text: "Start"
      onClicked: root.started()
    }
  }
}
