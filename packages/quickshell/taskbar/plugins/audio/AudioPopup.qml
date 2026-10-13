import QtQuick
import qs.components
import qs.config

PopupFrame {
  id: root

  implicitWidth: Theme.popupWidthCompact

  readonly property var dropdowns: [output, input, apps]

  // At most one dropdown open at a time.
  function collapseOthers(open) {
    for (const d of dropdowns) if (d !== open) d.expanded = false;
  }

  // ---- header ----------------------------------------------------------------
  PopupHeader {
    width: parent.width
    glyph: AudioService.icon
    title: "AUDIO"
    subtitle: !AudioService.live ? "OFF"
      : AudioService.muted ? "OUTPUT MUTED"
      : AudioService.nameOf(AudioService.sink).toUpperCase() + " · " + AudioService.volume + "%"
    subtitleColor: AudioService.live && !AudioService.muted ? Theme.green : Theme.muted

    PopupSwitch {
      checked: AudioService.live
      onToggled: AudioService.setMuted(AudioService.live)
    }
  }

  PopupSeparator { width: parent.width }

  // ---- output ----------------------------------------------------------------
  Column {
    width: parent.width
    spacing: 4

    AudioDeviceDropdown {
      id: output
      width: parent.width
      kind: "OUTPUT"
      nodes: AudioService.sinks
      current: AudioService.sink
      onSelected: node => AudioService.setSink(node)
      onExpandedChanged: if (expanded) root.collapseOthers(output)
    }

    AudioVolumeRow {
      width: parent.width
      node: AudioService.sink
    }
  }

  PopupSeparator { width: parent.width }

  // ---- input -----------------------------------------------------------------
  Column {
    width: parent.width
    spacing: 4

    AudioDeviceDropdown {
      id: input
      width: parent.width
      kind: "INPUT"
      nodes: AudioService.sources
      current: AudioService.source
      onSelected: node => AudioService.setSource(node)
      onExpandedChanged: if (expanded) root.collapseOthers(input)
    }

    AudioVolumeRow {
      width: parent.width
      node: AudioService.source
      icon: Theme.iconMicrophone
      mutedIcon: Theme.iconMicrophoneOff
    }
  }

  PopupSeparator { width: parent.width }

  // ---- applications ----------------------------------------------------------
  PopupDropdown {
    id: apps
    width: parent.width
    title: "APPLICATIONS: " + AudioService.streams.length
    disabled: AudioService.streams.length === 0
    maxListHeight: 4 * 46
    onExpandedChanged: if (expanded) root.collapseOthers(apps)

    Repeater {
      model: AudioService.streams

      Column {
        required property var modelData

        width: parent.width
        leftPadding: 12
        rightPadding: 10
        topPadding: 4

        ThemeText {
          width: parent.width - parent.leftPadding - parent.rightPadding
          text: AudioService.nameOf(modelData)
          elide: Text.ElideRight
          color: Theme.foreground2
          font.letterSpacing: 1
        }

        AudioVolumeRow {
          width: parent.width - parent.leftPadding - parent.rightPadding
          node: modelData
        }
      }
    }
  }
}
