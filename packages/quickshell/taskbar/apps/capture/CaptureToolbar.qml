import QtQuick
import qs.config
import qs.kit

// The capture panel, in the popups' style: a header with the current choice,
// WHAT (region / window / screen) and AS (shot / recording) as full-width
// choice rows; for a shot where it goes, for a recording its sound, frame
// rate, quality and encoder (auto: integrated GPU on battery); the pointer.
Rectangle {
  id: root

  readonly property var labels: ({
    region: "REGION", window: "WINDOW", screen: "SCREEN", shot: "SHOT", record: "RECORDING"
  })

  function home(path) {
    const h = CaptureService.shotDir.split("/").slice(0, 3).join("/");
    return path.startsWith(h) ? "~" + path.slice(h.length) : path;
  }

  implicitWidth: 400
  implicitHeight: content.implicitHeight + 32
  color: Theme.background0
  border.width: Theme.windowFrameWidth      // the popups' frame
  border.color: Theme.frame

  // keeps clicks on the panel from reaching the selection below
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
  }

  Column {
    id: content
    x: 16
    y: 16
    width: parent.width - 32
    spacing: 14

    KitHeader {
      icon: CaptureService.kind === "record" ? "video" : "camera"
      title: "Capture"
      subtitle: root.labels[CaptureService.mode] + " · " + root.labels[CaptureService.kind]
        + (CaptureService.cursor ? " · CURSOR" : "")

      KitButton {
        icon: "x"
        onClicked: CaptureService.close()
      }
    }

    KitLine {}

    // ---- what and how ---------------------------------------------------------------
    Column {
      width: parent.width
      spacing: 8

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
      spacing: 8

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

    // ---- where it goes: a shot always reaches the clipboard ---------------------------
    Column {
      width: parent.width
      spacing: 8

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
        onPicked: value => PluginSettings.set("capture", CaptureService.kind === "shot" ? "shotTarget" : "videoTarget", value)
      }
    }

    // ---- a recording: its settings ----------------------------------------------------
    Column {
      visible: CaptureService.kind === "record"
      width: parent.width
      spacing: 12

      Repeater {
        model: [
          { title: "SOUND", key: "audio", items: [{ label: "Off", value: "off", icon: "volume-x" },
                                                  { label: "System", value: "system", icon: "volume" },
                                                  { label: "Mic", value: "mic", icon: "mic" }] },
          { title: "FRAME RATE", key: "fps", items: [{ label: "30 fps", value: 30 }, { label: "60 fps", value: 60 }] },
          { title: "QUALITY", key: "quality", items: [{ label: "Low", value: "low" }, { label: "Medium", value: "medium" },
                                                      { label: "High", value: "high" }] },
          { title: "ENCODER", key: "encoder", items: [{ label: "Auto", value: "auto" }, { label: "iGPU", value: "igpu" },
                                                      { label: "GPU", value: "gpu" }, { label: "CPU", value: "cpu" }] }
        ]

        Column {
          id: setting

          required property var modelData

          width: parent.width
          spacing: 8

          KitLabel {
            text: setting.modelData.title
            value: setting.modelData.key === "encoder" && CaptureService.encoder === "auto"
              ? (CaptureService.encoderInUse === "igpu" ? "IGPU NOW · ON BATTERY" : "GPU NOW · ON POWER") : ""
          }

          KitChoices {
            width: parent.width
            stretch: true
            model: setting.modelData.items
            current: ({ audio: CaptureService.audio, fps: CaptureService.fps,
                        quality: CaptureService.quality, encoder: CaptureService.encoder })[setting.modelData.key]
            onPicked: value => {
              const key = setting.modelData.key;
              if (key === "audio") CaptureService.setAudio(value);
              else if (key === "fps") CaptureService.setFps(value);
              else if (key === "quality") CaptureService.setQuality(value);
              else CaptureService.setEncoder(value);
            }
          }
        }
      }

    }

    KitLine {}

    KitRow {
      label: "Hide cursor"
      hint: "keep the pointer out of the picture"

      KitSwitch {
        checked: !CaptureService.cursor
        onToggled: CaptureService.setCursor(!CaptureService.cursor)
      }
    }

    KitText {
      width: parent.width
      text: (CaptureService.mode === "region" ? "Drag to select" : CaptureService.mode === "window" ? "Click a window" : "Click a screen")
        + (CaptureService.kind === "record" ? " to record" : " to capture") + " · Esc to cancel"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
    }
  }
}
