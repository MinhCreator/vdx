pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Local Ollama on top of scripts/ollama.sh: server state, downloaded and
// loaded models, start / stop / pull / unload. Polled only while the AI
// popup shows its Ollama tab.
Singleton {
  id: root

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
    proc.command = ["bash", Theme.ollamaScript].concat(args);
    proc.running = true;
  }

  onWatchingChanged: if (watching) refresh()

  Timer {
    interval: Theme.ollamaIntervalMs
    running: root.watching
    repeat: true
    onTriggered: root.refresh()
  }

  Process {
    id: statusProc
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.status = JSON.parse(text); } catch (e) {}
      }
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector {
      onStreamFinished: {
        let o = null;
        try { o = JSON.parse(text); } catch (e) {}
        root.busy = null;
        if (!o?.ok) root.error = o?.error ?? "action failed";
        root.refresh();
      }
    }
  }
}
