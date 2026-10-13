pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Claude Code usage on top of scripts/claude.sh: plan limits (the `/usage`
// numbers, polled from the API), today's tokens from the local session logs,
// and the running sessions. The bar module and the popup only read these
// properties and call these functions.
Singleton {
  id: root

  property var usage: ({})                     // last good `claude.sh --usage`
  property string error: ""                    // last failure; `usage` keeps older data
  property real fetchedAt: 0                   // when `usage` was fetched
  property var today: ({})                     // see `claude.sh --today`
  property var sessions: []                    // see `claude.sh --sessions`
  property bool popupOpen: false

  readonly property string plan: usage.plan ?? ""
  readonly property var limits: usage.limits ?? []
  readonly property int peak: Math.max(0, ...limits.map(l => l.percent))
  readonly property int busy: sessions.filter(s => s.status === "busy").length
  readonly property bool refreshing: usageProc.running || todayProc.running

  function popupShown() {
    popupOpen = true;
    refresh();
  }

  function popupHidden() { popupOpen = false; }

  // The usage API rate-limits: on open, ask only if the data is a minute old.
  function refresh() {
    if (Date.now() - fetchedAt > 60000) run(usageProc, ["--usage"]);
    refreshLocal();
  }

  function refreshLocal() {
    run(todayProc, ["--today"]);
    run(sessionsProc, ["--sessions"]);
  }

  function run(proc, args) {
    if (proc.running) return;
    proc.command = ["bash", Theme.claudeScript].concat(args);
    proc.running = true;
  }

  function parse(text, fallback) {
    try { return JSON.parse(text); } catch (e) { return fallback; }
  }

  Timer {
    interval: Theme.claudeUsageIntervalMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.run(usageProc, ["--usage"])
  }

  Timer {
    interval: Theme.claudeLocalIntervalMs
    running: root.popupOpen
    repeat: true
    onTriggered: root.refreshLocal()
  }

  Process {
    id: usageProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text, { ok: false, error: "no answer" });
        if (o.ok) {
          root.usage = o;
          root.fetchedAt = Date.now();
          root.error = "";
        } else {
          root.error = o.error;
        }
      }
    }
  }

  Process {
    id: todayProc
    stdout: StdioCollector {
      onStreamFinished: root.today = root.parse(text, {})
    }
  }

  Process {
    id: sessionsProc
    stdout: StdioCollector {
      onStreamFinished: root.sessions = root.parse(text, [])
    }
  }
}
