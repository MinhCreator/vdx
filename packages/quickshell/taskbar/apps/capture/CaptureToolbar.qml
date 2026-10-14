import QtQuick
import qs.config
import qs.kit

// The capture toolbar: what to capture (region / window / screen), a shot or
// a recording, the pointer, and for a recording its sound, frame rate,
// quality and encoder (auto: integrated GPU on battery); close.
Rectangle {
  id: root

  implicitWidth: content.implicitWidth + 24
  implicitHeight: content.implicitHeight + 24
  color: Theme.background0
  border.width: Theme.frameWidth
  border.color: Theme.frame

  // keeps clicks on the toolbar from reaching the selection below
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
  }

  Column {
    id: content
    x: 12
    y: 12
    spacing: 10

    Row {
      spacing: 10

      KitChoices {
        model: [
          { label: "Region", value: "region", icon: "crop" },
          { label: "Window", value: "window", icon: "app-window" },
          { label: "Screen", value: "screen", icon: "monitor" }
        ]
        current: CaptureService.mode
        onPicked: value => CaptureService.setMode(value)
      }

      Rectangle { width: 1; height: 30; color: Theme.background3; anchors.verticalCenter: parent.verticalCenter }

      KitChoices {
        model: [
          { label: "Shot",   value: "shot",   icon: "camera" },
          { label: "Record", value: "record", icon: "video" }
        ]
        current: CaptureService.kind
        onPicked: value => CaptureService.setKind(value)
      }

      Rectangle { width: 1; height: 30; color: Theme.background3; anchors.verticalCenter: parent.verticalCenter }

      KitButton {
        icon: "eye-off"
        text: "Hide cursor"
        selected: !CaptureService.cursor
        onClicked: CaptureService.setCursor(!CaptureService.cursor)
      }

      KitButton {
        icon: "x"
        onClicked: CaptureService.close()
      }
    }

    Row {
      visible: CaptureService.kind === "record"
      spacing: 10

      KitText {
        anchors.verticalCenter: parent.verticalCenter
        text: "SOUND"
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 3
        font.letterSpacing: 1
      }

      KitChoices {
        model: [
          { label: "Off",    value: "off",    icon: "volume-x" },
          { label: "System", value: "system", icon: "volume" },
          { label: "Mic",    value: "mic",    icon: "mic" }
        ]
        current: CaptureService.audio
        onPicked: value => CaptureService.setAudio(value)
      }

      KitText {
        anchors.verticalCenter: parent.verticalCenter
        text: "FPS"
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 3
        font.letterSpacing: 1
      }

      KitChoices {
        model: [{ label: "30", value: 30 }, { label: "60", value: 60 }]
        current: CaptureService.fps
        onPicked: value => CaptureService.setFps(value)
      }

    }

    Row {
      visible: CaptureService.kind === "record"
      spacing: 10

      KitText {
        anchors.verticalCenter: parent.verticalCenter
        text: "QUALITY"
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 3
        font.letterSpacing: 1
      }

      KitChoices {
        model: [{ label: "Low", value: "low" }, { label: "Medium", value: "medium" }, { label: "High", value: "high" }]
        current: CaptureService.quality
        onPicked: value => CaptureService.setQuality(value)
      }

      KitText {
        anchors.verticalCenter: parent.verticalCenter
        text: "ENCODER"
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 3
        font.letterSpacing: 1
      }

      KitChoices {
        model: [
          { label: "Auto", value: "auto" },
          { label: "iGPU", value: "igpu" },
          { label: "GPU",  value: "gpu" },
          { label: "CPU",  value: "cpu" }
        ]
        current: CaptureService.encoder
        onPicked: value => CaptureService.setEncoder(value)
      }

      KitText {
        anchors.verticalCenter: parent.verticalCenter
        visible: CaptureService.encoder === "auto"
        text: CaptureService.encoderInUse === "igpu" ? "iGPU · on battery" : "GPU · on power"
        color: Theme.muted
        font.pixelSize: Theme.fontSize - 2
      }
    }

    KitText {
      text: (CaptureService.mode === "region" ? "Drag to select"
           : CaptureService.mode === "window" ? "Click a window"
           : "Click a screen")
        + (CaptureService.kind === "record" ? " to record" : " to capture")
        + " · Esc or right click to cancel"
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 2
    }
  }
}
