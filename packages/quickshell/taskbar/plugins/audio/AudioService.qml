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

  // Ports per device ({port, type, active, list} by node name, see audio.sh):
  // short device names ("Speakers", "Headphones") and the headphones state.
  property var ports: ({})
  readonly property bool headphones: (ports[sink?.name]?.type ?? "").startsWith("Head")

  // Device lists for the popup: one entry per port, so the built-in card shows
  // both "Speakers" and "Headphones". Built-in speakers and mic stay listed
  // with the jack in; other unplugged ports are left out.
  readonly property var outputs: entriesOf(sinks)
  readonly property var inputs: entriesOf(sources)
  readonly property string outputKey: keyOf(sink)
  readonly property string inputKey: keyOf(source)

  // Whether output or input is still live; the header switch mutes both.
  readonly property bool live: !muted || !(source?.audio?.muted ?? true)

  // headphones in the jack: a sink's headphone port is available (its jack
  // detection works, unlike the mic's)
  readonly property bool jackIn: sinks.some(n => (ports[n.name]?.list ?? []).some(p => p.type.startsWith("Head") && p.available))

  function nodesOf(type) {
    return Pipewire.nodes.values.filter(n => n.type === type);
  }

  function nameOf(node) {
    if (!node) return "—";
    return node.properties["application.name"] || ports[node.name]?.port
        || node.description || node.nickname || node.name;
  }

  function keyOf(node) { return node ? node.name + "|" + (ports[node.name]?.active ?? "") : ""; }

  function entriesOf(nodes) {
    const entries = [];
    for (const node of nodes) {
      const info = ports[node.name];
      // a jack mic that can't tell it is plugged (availability unknown) is
      // listed only while headphones are in, or when it is the one in use
      const list = (info?.list ?? []).filter(p => p.name === info.active || p.type === "Speaker" || p.name.includes("internal")
                                               || (p.available && !(p.unknown && p.type === "Mic" && !root.jackIn)));
      if (list.length === 0)
        entries.push({ key: node.name + "|" + (info?.active ?? ""), node: node, port: "", label: nameOf(node), about: node.description });
      for (const p of list)
        entries.push({ key: node.name + "|" + p.name, node: node, port: p.name, label: p.port, about: node.description });
    }
    // ports with the same name on different devices get the device appended
    return entries.map(e => Object.assign({}, e, {
      label: (entries.filter(o => o.label === e.label).length > 1 ? e.label + " · " + e.about : e.label).toUpperCase()
    }));
  }

  function select(entry) {
    if (!entry) return;
    const sink = entry.node.type === PwNodeType.AudioSink;
    if (sink) setSink(entry.node); else setSource(entry.node);
    if (entry.port !== "") {
      Quickshell.execDetached(["pactl", sink ? "set-sink-port" : "set-source-port", entry.node.name, entry.port]);
      portRefresh.restart();
    }
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
    id: portRefresh
    interval: 300
    onTriggered: portProc.running = true
  }

  Timer {
    interval: Theme.audioPortIntervalMs
    running: true
    repeat: true
    onTriggered: portProc.running = true
  }
}
