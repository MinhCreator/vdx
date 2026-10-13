import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
import qs.config

// pulseaudio (mirrors themes/<t>/waybar/modules/audio.jsonc):
//   format       "{icon}  {volume}"        (no % suffix)
//   format-muted "<span fg=red>  Muted</span>"
//   format-icons { headphone , default [  ] }
//   scroll-step 5 · max-volume 150
//   on-click     wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
//
// Volume/mute come live from Pipewire; the active sink port (headphone) is the
// one detail Pipewire doesn't expose cleanly, so a tiny pactl poll mirrors
// waybar's port detection. Muted text uses the theme's red (inline span in the
// config overrides the CSS color), otherwise foreground0.

Item {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var audio: root.sink ? root.sink.audio : null
  readonly property bool muted: root.audio ? root.audio.muted : false
  readonly property real volume: root.audio ? root.audio.volume : 0  // 0..1 => 0..100%
  readonly property int percent: Math.min(Theme.audioMaxPercent, Math.round(root.volume * 100))

  // waybar default icons: idx = clamp(percent / (100 / 3), 0, 2)
  readonly property int iconIndex: Math.min(2, Math.floor(root.percent * 3 / 100))
  readonly property string defaultIcon: [Theme.iconVolumeOff, Theme.iconVolumeLow, Theme.iconVolumeHigh][root.iconIndex]

  property bool headphones: false
  readonly property string icon: root.headphones ? Theme.iconHeadphone : root.defaultIcon

  readonly property string labelText: root.muted
      ? Theme.iconMuted + "  Muted"
      : root.icon + "  " + root.percent

  Text {
    id: label
    text: root.labelText
    color: root.muted ? Theme.red : Theme.foreground0
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  // Active default-sink port (headphone jack) — polls pactl like waybar reads
  // the port name from the pulse backend.
  Process {
    id: portProc
    command: ["bash", Theme.sinkPortScript]
    running: true

    stdout: StdioCollector {
      onStreamFinished: root.headphones = this.text.trim() === "headphone"
    }
  }

  Timer {
    interval: Theme.audioPortIntervalMs
    running: true
    repeat: true
    onTriggered: portProc.running = true
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor // waybar: HAND2 when the module has events
    // waybar on-click: wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    onClicked: Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    // A sibling WheelHandler never receives wheel events on a layer-shell
    // surface, so the scroll is handled on the MouseArea (same path as clicks).
    //   scroll-step 5 · max-volume 150 (limit 1.5)
    onWheel: (wheel) => {
      const delta = wheel.angleDelta.y
      const step = Theme.audioScrollStep + "%"
      const limit = (Theme.audioMaxPercent / 100).toString()
      if (delta > 0)
        Quickshell.execDetached(["wpctl", "set-volume", "-l", limit, "@DEFAULT_AUDIO_SINK@", step + "+"])
      else if (delta < 0)
        Quickshell.execDetached(["wpctl", "set-volume", "-l", limit, "@DEFAULT_AUDIO_SINK@", step + "-"])
      wheel.accepted = true
    }
  }
}
