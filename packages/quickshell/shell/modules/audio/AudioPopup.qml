import QtQuick
import Quickshell.Services.Pipewire
import qs.config
import qs.kit

// Audio: output and input devices with their volume, then each application's
// stream.
KitFrame {
  id: root

  readonly property bool headphones: AudioService.headphones

  // Set while the popup is shown; the input level meter runs only then.
  property bool open: false

  // Live input level: the peak in dBFS mapped onto 0..1 over -60..0 dB.
  // PwNodePeakMonitor reports the cube root of the sample peak, so dBFS = 60·log10.
  readonly property real micLevel: {
    const peak = micPeak.peak;
    return peak > 0 ? Math.max(0, Math.min(1, (60 * Math.log10(peak) + 60) / 60)) : 0;
  }

  PwNodePeakMonitor {
    id: micPeak
    node: AudioService.source
    enabled: root.open && !(AudioService.source?.audio?.muted ?? true)
  }

  // ---- header ----
  KitHeader {
    icon: !AudioService.live || AudioService.muted ? "volume-x" : root.headphones ? "headphones" : "volume"
    iconColor: AudioService.live && !AudioService.muted ? Theme.foreground0 : Theme.muted
    title: "Audio"
    subtitle: !AudioService.live ? "OFF"
      : AudioService.muted ? "OUTPUT MUTED"
      : "VOLUME " + AudioService.volume + "%"

    KitSwitch {
      anchors.verticalCenter: parent.verticalCenter
      checked: AudioService.live
      onToggled: AudioService.setMuted(AudioService.live)
    }
  }

  KitLine {}

  // ---- output ----
  Column {
    width: parent.width
    spacing: 10

    KitLabel { text: "OUTPUT" }

    AudioDeviceDropdown {
      id: output
      label: "Device"
      hint: "Default output"
      entries: AudioService.outputs
      current: AudioService.outputKey
      onExpandedChanged: if (expanded) input.expanded = false
    }

    AudioVolumeRow {
      node: AudioService.sink
      iconOn: root.headphones ? "headphones" : "volume"
    }
  }

  KitLine {}

  // ---- input ----
  Column {
    width: parent.width
    spacing: 10

    KitLabel { text: "INPUT" }

    AudioDeviceDropdown {
      id: input
      label: "Device"
      hint: "Default input"
      entries: AudioService.inputs
      current: AudioService.inputKey
      onExpandedChanged: if (expanded) output.expanded = false
    }

    AudioVolumeRow {
      node: AudioService.source
      iconOn: "mic"
      iconOff: "mic-off"
    }

    // what the microphone hears right now: green, yellow near the top, red at clipping
    Column {
      width: parent.width
      spacing: 5

      KitInfo {
        label: "Level"
        value: micPeak.enabled ? Math.round(root.micLevel * 100) + "%" : "muted"
        valueColor: micPeak.enabled ? Theme.foreground2 : Theme.gray
      }

      Rectangle {
        width: parent.width
        height: 4
        color: Theme.background3

        Rectangle {
          width: root.micLevel * parent.width
          height: parent.height
          color: root.micLevel > 0.92 ? Theme.red : root.micLevel > 0.75 ? Theme.yellow : Theme.green

          Behavior on width { NumberAnimation { duration: 60 } }
        }
      }
    }
  }

  KitLine {}

  // ---- applications ----
  Column {
    width: parent.width
    spacing: Theme.gapMedium

    KitLabel { text: "APPLICATIONS (" + AudioService.streams.length + ")" }

    KitText {
      visible: AudioService.streams.length === 0
      text: "Nothing is playing."
      color: Theme.muted
      font.pixelSize: Theme.fontSize - 1
    }

    Repeater {
      model: AudioService.streams

      Column {
        required property var modelData

        width: parent.width
        spacing: Theme.gapTight

        KitText {
          width: parent.width
          text: AudioService.nameOf(modelData)
          elide: Text.ElideRight
          color: Theme.foreground2
          font.pixelSize: Theme.fontSize - 1
        }

        AudioVolumeRow { node: modelData }
      }
    }
  }
}
