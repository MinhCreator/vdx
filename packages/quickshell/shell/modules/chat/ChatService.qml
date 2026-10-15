pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// A chat with a free opencode model (`opencode run`, the read-only built-in
// "plan" agent, in an empty folder of its own — it can't run commands or touch
// files). One conversation at a time, kept by opencode's session: each message
// continues it; New chat starts another. Model (any free one opencode lists)
// and whether opencode's background server stays up: Modules › Chat.
Singleton {
  id: root

  readonly property string model: ModuleSettings.get("chat", "model", "opencode/big-pickle")
  readonly property string workDir: Quickshell.env("HOME") + "/.cache/dotfiles/chat"
  // off: no background server — each message starts its own and it goes
  // after the answer (a bit slower); switching off stops the running one
  readonly property bool keepServer: ModuleSettings.get("chat", "server", true)
  onKeepServerChanged: if (!keepServer) Quickshell.execDetached(["opencode", "service", "stop"])

  // ---- free models ----
  property var models: []                   // [{label, value}]: Big Pickle and the "-free" ones
  function loadModels() { if (models.length === 0 && !modelsProc.running) modelsProc.running = true; }
  function nameOf(id) {
    return id.replace(/^opencode\//, "").replace(/-free$/, "").split("-")
             .map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(" ");
  }

  Process {
    id: modelsProc
    command: ["opencode", "models"]
    stdout: StdioCollector {
      onStreamFinished: root.models = text.split("\n").map(l => l.trim())
        .filter(l => l === "opencode/big-pickle" || /^opencode\/.*-free$/.test(l))
        .map(l => ({ label: root.nameOf(l), value: l }))
    }
  }

  // ---- state ----
  property var messages: []                 // [{role: user | assistant | error, text}]
  property string session: ""
  property bool busy: false

  function send(text) {
    const t = text.trim();
    if (t === "" || busy) return;
    messages = messages.concat([{ role: "user", text: t }]);
    busy = true;
    proc.reply = "";
    // stdin closed: with a pipe open, opencode waits to read the message from it
    proc.command = ["bash", "-c", 'mkdir -p "$1" && cd "$1" && shift && exec opencode run "$@" </dev/null', "_", workDir,
                    "-m", model, "--agent", "plan", "--format", "json"].concat(keepServer ? [] : ["--standalone"])
                   .concat(session !== "" ? ["-s", session] : []).concat([t]);
    proc.running = true;
  }

  function reset() {
    if (busy) return;
    messages = [];
    session = "";
  }

  Process {
    id: proc
    property string reply: ""
    stdout: SplitParser {
      onRead: line => {
        let d;
        try { d = JSON.parse(line); } catch (e) { return; }
        if (d.sessionID && root.session === "") root.session = d.sessionID;
        if (d.type === "text" && d.part?.text) proc.reply += d.part.text;
      }
    }
    stderr: StdioCollector { id: err }
    onExited: code => {
      root.busy = false;
      const errText = err.text.replace(/\u001b\[[0-9;]*m/g, "").trim().split("\n").filter(l => l).pop() ?? "";
      if (proc.reply !== "")
        root.messages = root.messages.concat([{ role: "assistant", text: proc.reply.trim() }]);
      else
        root.messages = root.messages.concat([{ role: "error", text: code === 0 ? "No answer." : (errText || "opencode failed") }]);
    }
  }
}
