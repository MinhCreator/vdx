import QtQuick
import qs.config
import qs.kit

// Audio: output and input devices with their volume, then each application's
// stream.
KitFrame {
  id: root

  readonly property bool headphones: AudioService.headphones

  // ---- header ----------------------------------------------------------------
  KitHeader {
    icon: !AudioService.live || AudioService.muted ? "volume-x" : root.headphones ? "headphones" : "volume"
    glyphColor: AudioService.live && !AudioService.muted ? Theme.foreground0 : Theme.muted
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

  // ---- output ----------------------------------------------------------------
  Column {
    width: parent.width
    spacing: 10

    KitLabel { text: "OUTPUT" }

    AudioDeviceDropdown {
      id: output
      label: "Device"
      hint: "default output"
      nodes: AudioService.sinks
      current: AudioService.sink
      onSelected: node => AudioService.setSink(node)
      onExpandedChanged: if (expanded) input.expanded = false
    }

    AudioVolumeRow {
      node: AudioService.sink
      iconOn: root.headphones ? "headphones" : "volume"
    }
  }

  KitLine {}

  // ---- input -----------------------------------------------------------------
  Column {
    width: parent.width
    spacing: 10

    KitLabel { text: "INPUT" }

    AudioDeviceDropdown {
      id: input
      label: "Device"
      hint: "default input"
      nodes: AudioService.sources
      current: AudioService.source
      onSelected: node => AudioService.setSource(node)
      onExpandedChanged: if (expanded) output.expanded = false
    }

    AudioVolumeRow {
      node: AudioService.source
      iconOn: "mic"
      iconOff: "mic-off"
    }
  }

  KitLine {}

  // ---- applications ----------------------------------------------------------
  Column {
    width: parent.width
    spacing: 8

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
        spacing: 2

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
