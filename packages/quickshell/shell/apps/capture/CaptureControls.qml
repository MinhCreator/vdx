import QtQuick
import Quickshell
import qs.config
import qs.kit

// The capture choices, one set for the bar popup and the app's window: what
// (region / window / screen), as (shot / recording), a recording's sound, where
// it goes (set in Shell Manager, shown here), the pointer, and Start. The
// quality, frame rate, codec and encoder are one-time options in Shell Manager.
Column {
  id: root

  signal started()

  readonly property var labels: ({
    region: "REGION", window: "WINDOW", screen: "SCREEN", shot: "SHOT", record: "RECORDING"
  })

  // the target as Shell Manager set it, read as the user would write it
  readonly property string saveTo: {
    if (CaptureService.kind === "shot") {
      if (CaptureService.shotTarget === "clipboard") return "CLIPBOARD ONLY";
      if (CaptureService.shotTarget === "ask") return "ASKS WHERE";
      return home(CaptureService.shotDir).toUpperCase();
    }
    return CaptureService.videoTarget === "ask" ? "ASKS WHERE" : home(CaptureService.videoDir).toUpperCase();
  }

  function home(path) {
    const h = Quickshell.env("HOME");
    return h !== "" && path.startsWith(h) ? "~" + path.slice(h.length) : path;
  }

  spacing: Theme.gapGroup

  // ---- a recording running: stop it here ----
  KitRow {
    visible: CaptureService.recording
    label: "Recording"
    hint: "Stop to save it"

    KitButton {
      width: Theme.buttonWidth
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

    Column {
      visible: CaptureService.kind === "record"
      width: parent.width
      spacing: Theme.gapMedium

      KitLabel { text: "SOUND" }

      KitChoices {
        width: parent.width
        stretch: true
        model: [
          { label: "Off", value: "off", icon: "volume-x" },
          { label: "System", value: "system", icon: "volume" },
          { label: "Mic", value: "mic", icon: "mic" }
        ]
        current: CaptureService.audio
        onPicked: value => CaptureService.setAudio(value)
      }
    }

    KitLabel {
      text: "SAVE TO"
      value: root.saveTo
    }

    // the codec's most important problem, in yellow when it hurts
    Column {
      visible: CaptureService.codecNote?.warn ?? false
      width: parent.width
      spacing: Theme.gapHair

      KitText {
        width: parent.width
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSize - 2
        font.weight: Font.ExtraBold
        color: Theme.yellow
        text: CaptureService.codecNote?.title ?? ""
      }

      KitText {
        width: parent.width
        wrapMode: Text.WordWrap
        font.pixelSize: Theme.fontSize - 2
        color: Theme.yellow
        text: CaptureService.codecNote?.text ?? ""
      }
    }

    KitLine {}

    KitRow {
      label: "Show cursor"
      hint: "Off: the pointer stays out"

      KitSwitch {
        checked: CaptureService.cursor
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
