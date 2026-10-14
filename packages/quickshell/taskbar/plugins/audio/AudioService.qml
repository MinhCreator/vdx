pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.config

// Audio devices, application streams and volumes over Pipewire. The bar module
// and the popup only read these properties and call these functions.
Singleton {
  id: root

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource
  readonly property var sinks: nodesOf(PwNodeType.AudioSink)
  readonly property var sources: nodesOf(PwNodeType.AudioSource)
  readonly property var streams: nodesOf(PwNodeType.AudioOutStream)   // application playback

  readonly property bool muted: sink?.audio?.muted ?? false
  readonly property int volume: Math.round((sink?.audio?.volume ?? 0) * 100)

  // Active port per device ({port, type} by node name, see audio.sh): gives
  // short device names ("Speakers", "Headphones") and the headphones state.
  property var ports: ({})
  readonly property bool headphones: (ports[sink?.name]?.type ?? "").startsWith("Head")

  // Whether output or input is still live; the header switch mutes both.
  readonly property bool live: !muted || !(source?.audio?.muted ?? true)

  function nodesOf(type) {
    return Pipewire.nodes.values.filter(n => n.type === type);
  }

  function nameOf(node) {
    if (!node) return "—";
    return node.properties["application.name"] || ports[node.name]?.port
        || node.description || node.nickname || node.name;
  }

  // Name within a device list; devices sharing a port name ("Headphones" on the
  // jack and over Bluetooth) get their full description appended.
  function deviceName(node, list) {
    const name = nameOf(node);
    const shared = list.filter(n => nameOf(n) === name).length > 1;
    return (shared ? name + " · " + (node.description || node.name) : name).toUpperCase();
  }

  function setSink(node) { Pipewire.preferredDefaultAudioSink = node; }
  function setSource(node) { Pipewire.preferredDefaultAudioSource = node; }

  function toggleMute(node) {
    if (node?.audio) node.audio.muted = !node.audio.muted;
  }

  function setMuted(muted) {
    for (const node of [sink, source])
      if (node?.audio) node.audio.muted = muted;
  }

  // value: 0..1 of 100 %; the bar wheel may push the sink up to Theme.audioMaxPercent.
  function setVolume(node, value) {
    if (node?.audio) node.audio.volume = Math.max(0, Math.min(Theme.audioMaxPercent / 100, value));
  }

  function stepVolume(percent) {
    setVolume(sink, (volume + percent) / 100);
  }

  PwObjectTracker {
    objects: [root.sink, root.source].concat(root.streams)
  }

  Process {
    id: portProc
    command: ["bash", Theme.audioScript]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.ports = JSON.parse(text); } catch (e) {}
      }
    }
  }

  Timer {
    interval: Theme.audioPortIntervalMs
    running: true
    repeat: true
    onTriggered: portProc.running = true
  }
}
