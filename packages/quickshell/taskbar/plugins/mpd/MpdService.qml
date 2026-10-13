pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// MPD player shared by the music and radio plugins (scripts/music.sh): one
// state stream and the playback commands. Each plugin adds its own data on top
// (MusicService, RadioService).
Singleton {
  id: root

  property var player: ({})                    // see `music.sh --status`

  readonly property bool service: player.service ?? false
  readonly property bool playing: player.state === "playing"
  readonly property bool stopped: !service || player.state === "stop" || source === ""
  readonly property string source: player.source ?? ""     // likes | radio | ""
  readonly property string file: player.file ?? ""
  readonly property real duration: player.duration ?? 0
  property real elapsed: 0                     // ticks locally between MPD events

  property var busy: null                      // what is being started, for its spinner
  property string error: ""

  signal queueChanged()

  // ---- playback --------------------------------------------------------------
  function control(args) {
    Quickshell.execDetached(["bash", Theme.musicScript].concat(args));
  }

  function toggle() { control(["--toggle"]); }
  function stop() { control(["--stop"]); }
  function next() { control(["--next"]); }
  function prev() { control(["--prev"]); }
  function play(pos) { control(pos === undefined ? ["--play"] : ["--play", String(pos)]); }
  function toggleRandom() { control(["--random"]); }
  function cycleRepeat() { control(["--repeat"]); }

  function seek(fraction) {
    elapsed = Math.round(fraction * duration);
    control(["--seek", String(elapsed)]);
  }

  // Replaces the queue (likes or a station); errors land in `error`.
  function load(value, args) {
    busy = value;
    error = "";
    run(loadProc, args);
  }

  // ---- internals -----------------------------------------------------------
  function run(proc, args) {
    proc.command = ["bash", Theme.musicScript].concat(args);
    proc.running = true;
  }

  function parse(text) {
    try { return JSON.parse(text); } catch (e) { return null; }
  }

  Timer {
    interval: 1000
    running: root.playing && root.source === "likes"
    repeat: true
    onTriggered: root.elapsed = Math.min(root.duration, root.elapsed + 1)
  }

  Timer {
    id: listenRestart
    interval: Theme.musicRestartMs
    onTriggered: listenProc.running = true
  }

  Process {
    id: listenProc
    command: ["bash", Theme.musicScript, "--listen"]
    running: true
    stdout: SplitParser {
      onRead: line => {
        const o = root.parse(line);
        if (!o) return;
        const changed = o.length !== root.player.length;
        root.player = o;
        root.elapsed = o.elapsed ?? 0;
        if (changed) root.queueChanged();
      }
    }
    onExited: listenRestart.start()
  }

  Process {
    id: loadProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.busy = null;
        if (!o?.ok) root.error = o?.error ?? "could not start playback";
        root.queueChanged();
      }
    }
  }
}
