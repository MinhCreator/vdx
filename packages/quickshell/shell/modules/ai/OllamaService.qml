pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../../kit/reply.js" as Reply

// Local Ollama on top of scripts/ollama.sh: server state, downloaded and
// loaded models, start / stop / pull / unload. Polled only while the AI
// popup shows its Ollama tab.
Singleton {
  id: root

  // ---- tuning ----
  readonly property int pollMs: 5000                   // status poll while the tab is open
  readonly property string coachModel: "qwen2.5:1.5b"  // the nvim habit coach's model
  readonly property string script: Paths.scriptsDir + "/ollama.sh"

  property var status: ({})                    // see `ollama.sh --status`
  property bool watching: false                // the Ollama tab is visible
  property var busy: null                      // "server" or a model name being worked on
  property string error: ""

  readonly property bool installed: status.installed ?? true
  readonly property bool running: status.running ?? false
  readonly property var models: status.models ?? []
  readonly property var loaded: status.loaded ?? []

  function vramOf(name) { return loaded.find(m => m.name === name)?.vram ?? 0; }
  function hasModel(name) { return models.some(m => m.name === name); }

  function refresh() { run(statusProc, ["--status"]); }

  function setRunning(on) { act("server", [on ? "--start" : "--stop"]); }
  function pull(name) { act(name, ["--pull", name]); }
  function unload(name) { act(name, ["--unload", name]); }

  function act(what, args) {
    if (actionProc.running) return;
    busy = what;
    error = "";
    run(actionProc, args);
  }

  function run(proc, args) {
    if (proc.running) return;
    proc.command = ["bash", root.script].concat(args);
    proc.running = true;
  }

  onWatchingChanged: if (watching) refresh()

  Timer {
    interval: root.pollMs
    running: root.watching
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = Reply.parse(text, "ollama.sh", null);
        if (o) root.status = o;
      }
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = Reply.parse(text, "ollama.sh");
        root.busy = null;
        if (!o?.ok) root.error = o?.error ?? "action failed";
        root.refresh();
      }
    }
  }
}
