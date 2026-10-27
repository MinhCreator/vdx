pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../../kit/reply.js" as Reply

// Codex CLI plan limits on top of scripts/codex.sh: the numbers of its last
// answer, read from its session logs (no network). The bar module and the
// popup only read these properties and call refresh().
Singleton {
  id: root

  // ---- tuning ----
  readonly property int pollMs: 60000        // the logs are local: cheap to read
  readonly property string script: Paths.scriptsDir + "/codex.sh"

  property var usage: ({})                   // last good `codex.sh --usage`
  property string error: ""

  readonly property string plan: usage.plan ?? ""
  readonly property var limits: usage.limits ?? []
  // when Codex last saw these numbers (ms), 0 before any
  readonly property real fetchedAt: usage.at ? new Date(usage.at).getTime() : 0
  readonly property bool refreshing: proc.running

  function refresh() {
    if (proc.running) return;
    proc.command = ["bash", root.script, "--usage"];
    proc.running = true;
  }

  Timer {
    interval: root.pollMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Process {
    id: proc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = Reply.parse(text, "codex.sh", { ok: false, error: "no answer" });
        if (o.ok) { root.usage = o; root.error = ""; }
        else root.error = o.error;
      }
    }
  }
}
