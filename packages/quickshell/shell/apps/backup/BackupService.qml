pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.apps.auth
import qs.config
import "../../kit/reply.js" as Reply

// The backups' state (scripts/backup.py), shared by the window. Reads (the
// status, the snapshots, one folder of a snapshot) run on their own; writes
// go through `job`, one at a time: a backup streams its progress, every
// other job ends with one reply. Reinstalling packages is a root action:
// RootService shows its steps and asks for the password.
Singleton {
  id: root

  readonly property string script: Paths.scriptsDir + "/backup.py"

  // ---- tuning ----
  readonly property int messageMs: 6000
  readonly property int revealMs: 20000     // the password stays on show this long
  // every text button of the backups shares this width, so a column of them lines up
  readonly property int buttonWidth: 120

  // ---- settings and status ----
  property var config: ({})
  property var last: null                   // {ts, ok, message, auto, …} or null
  property bool configured: false           // a repository and its password
  property bool resticFound: true
  property bool claude: false               // the claude command is there: the AI analysis is offered
  property bool loaded: false

  function refresh() {
    if (!statusProc.running) statusProc.running = true;
  }

  Process {
    id: statusProc
    command: ["python3", root.script, "--json", "status"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = Reply.parse(text, "backup.py");
        if (!r.ok) { root.done(false, r.error); return; }
        root.config = r.config;
        root.last = r.last;
        root.configured = r.configured;
        root.resticFound = r.restic;
        root.claude = r.claude === true;
        root.loaded = true;
      }
    }
  }

  // ---- the restore guide (the same text as `backup.py guide`) ----
  property var guideLines: []
  property string tabRequest: ""            // a part of the shell asks the window for a tab: "restore", …

  function loadGuide() {
    if (!guideProc.running) guideProc.running = true;
  }

  Component.onCompleted: loadGuide()

  Process {
    id: guideProc
    command: ["python3", root.script, "--json", "guide"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = Reply.parse(text, "backup.py");
        if (r.ok) root.guideLines = r.lines;
      }
    }
  }

  // ---- sizes: the repository on disk, what the newest snapshot restores to, each folder's size ----
  property real onDisk: -1                  // bytes; -1 until measured
  property real restoreSize: -1
  property var sizes: ({})                  // absolute path -> bytes, of the folders listed

  function loadSize() {
    if (!sizeProc.running && configured) sizeProc.running = true;
  }

  Process {
    id: sizeProc
    command: ["python3", root.script, "--json", "size"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = Reply.parse(text, "backup.py");
        if (!r.ok) return;
        root.onDisk = r.on_disk;
        root.restoreSize = r.restore;
      }
    }
  }

  function loadSizes(snap, path) {
    if (sizesProc.running) return;
    sizesProc.command = ["python3", root.script, "--json", "sizes", snap, path];
    sizesProc.running = true;
  }

  Process {
    id: sizesProc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = Reply.parse(text, "backup.py");
        if (r.ok) root.sizes = Object.assign({}, root.sizes, r.sizes);
      }
    }
  }

  // ---- snapshots ----
  property var snapshots: []                // newest first
  property bool listing: false

  function loadSnapshots() {
    if (snapsProc.running) return;
    listing = true;
    snapsProc.running = true;
  }

  Process {
    id: snapsProc
    command: ["python3", root.script, "--json", "snapshots"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.listing = false;
        const r = Reply.parse(text, "backup.py");
        if (!r.ok) { root.done(false, r.error); return; }
        root.snapshots = r.snapshots;
      }
    }
  }

  // the folder open in the Snapshots page: its entries, one level at a time
  property string snapshot: ""              // short id; "" when none is open
  property string folder: "/"
  property var entries: []
  property bool browsing: false
  property var browseNext: null             // the latest folder asked while one is listed

  function browse(snap, path) {
    if (lsProc.running) { browseNext = { snapshot: snap, path: path }; return; }
    snapshot = snap;
    folder = path;
    entries = [];
    browsing = true;
    lsProc.command = ["python3", root.script, "--json", "ls", snap, path];
    lsProc.running = true;
    loadSizes(snap, path);
  }

  function leave() { snapshot = ""; entries = []; folder = "/"; }

  Process {
    id: lsProc
    stdout: StdioCollector {
      onStreamFinished: {
        root.browsing = false;
        const r = Reply.parse(text, "backup.py");
        if (!r.ok) { root.done(false, r.error); return; }
        // an answer for a folder left meanwhile is dropped
        if (r.path === root.folder) root.entries = r.entries;
      }
    }
    onRunningChanged: if (!running && root.browseNext) {
      const next = root.browseNext;
      root.browseNext = null;
      root.browse(next.snapshot, next.path);
    }
  }

  // ---- jobs: one at a time ----
  property bool busy: false
  property string jobKind: ""               // run init password config schedule restore packages forget verify
  property real progress: -1                // 0–100 while a backup runs
  property var answer: null                 // the job's reply, once it has come
  property string status: ""                // "" | ok | error
  property string message: ""
  property string revealed: ""              // the password, shown on request
  property string restored: ""              // the folder of the last restore
  property var aiSuggestions: []            // [{path, shown, mb, days, why, risk}] from Claude
  property var aiPicked: ({})               // path -> bool: what the user leaves out

  function job(kind, args) {
    if (busy) return false;
    busy = true;
    jobKind = kind;
    answer = null;
    progress = -1;
    status = "";
    jobProc.command = ["python3", root.script, "--json"].concat(args);
    jobProc.running = true;
    return true;
  }

  function feed(line) {
    const r = Reply.parse(line, "backup.py", null);
    if (r === null) return;
    if (r.progress !== undefined) root.progress = r.progress;
    else root.answer = r;
  }

  Process {
    id: jobProc
    stdout: SplitParser { onRead: line => root.feed(line) }
    stderr: StdioCollector { id: jobErr }
    onExited: {
      const kind = root.jobKind;
      const r = root.answer ?? { ok: false, error: (jobErr.text.trim().split("\n").pop() || "no reply from the backup script").slice(0, 200) };
      root.busy = false;
      root.progress = -1;
      root.finish(kind, r);
    }
  }

  function finish(kind, r) {
    if (kind === "password") {
      if (r.ok) { root.revealed = r.password; hideSecret.restart(); }
      else root.done(false, r.error);
      return;
    }
    if (kind === "packages") {
      if (!r.ok) { root.done(false, r.error); return; }
      if (!RootService.request("Backups", "Reinstall packages", r.steps, r.script, "backup-packages"))
        root.done(false, "another root action is waiting");
      else root.message = r.message;
      return;
    }
    if (kind === "pick") {
      if (r.ok) root.init(r.path);
      else root.done(false, r.error);
      return;
    }
    if (kind === "ai") {
      if (!r.ok) { root.done(false, r.error); return; }
      const picked = {};
      r.suggestions.forEach(s => picked[s.path] = s.risk === "low");
      root.aiSuggestions = r.suggestions;
      root.aiPicked = picked;
      root.done(true, r.message);
      return;
    }
    if (kind === "rootplan") {
      if (!r.ok) { root.done(false, r.error); return; }
      if (!RootService.request("Backups", "Back up the root-only files", r.steps, r.script, "backup-root"))
        root.done(false, "another root action is waiting");
      return;
    }
    if (kind === "aur") {
      if (!r.ok) { root.done(false, r.error); return; }
      // yay builds each one in a terminal, shows its PKGBUILD and asks for the password itself
      Quickshell.execDetached(["kitty", "-e", "bash", "-c",
        "yay -S --needed --sudo pkexec \"$@\"; echo; read -rp 'press Enter to close ' _",
        "bash"].concat(r.aur));
      root.done(true, r.message + " · in the terminal");
      return;
    }
    if (kind === "config") {
      if (r.ok) root.config = r.config;
      else root.done(false, r.error);
      return;
    }
    if (r.ok && (kind === "schedule")) root.config = r.config;
    // a manual run also takes the root-only files, when the switch is on (the root panel asks the password)
    if (kind === "run" && r.ok && root.config.sources && root.config.sources.root === true) job("rootplan", ["root-plan"]);
    if (r.ok && kind === "restore") root.restored = r.target;
    done(r.ok, r.ok ? r.message : r.error);
    if (kind === "run" || kind === "init" || kind === "schedule" || kind === "forget") {
      refresh();
      loadSnapshots();
      loadSize();
    }
  }

  Connections {
    target: RootService
    function onFinished(tag, ok, error) {
      if (tag === "backup-root") {
        root.done(ok, ok ? "Root-only files backed up" : error === "cancelled" ? "Root-only backup cancelled" : error);
        return;
      }
      if (tag !== "backup-packages") return;
      root.done(ok, ok ? "Packages reinstalled" : error === "cancelled" ? "Reinstall cancelled" : error);
    }
  }

  // ---- actions ----
  function runNow() { return job("run", ["run"]); }
  function cancel() { if (busy && jobKind === "run") jobProc.signal(2); }
  function init(repo) { return job("init", ["init", "--repo", repo]); }
  // any folder, chosen in the Files window; it becomes the repository at once
  function pick() { return job("pick", ["pick"]); }
  function showPassword() { return job("password", ["password"]); }
  function setConfig(change) { return job("config", ["config", "set", JSON.stringify(change)]); }
  function setSchedule(mode, time) { return job("schedule", ["schedule", mode, "--time", time]); }
  function verify(deep) { return job("verify", ["verify"].concat(deep ? ["--deep"] : [])); }
  function packages(snap) { return job("packages", ["packages", snap]); }
  function aur(snap) { return job("aur", ["aur", snap]); }
  function analyze() { return job("ai", ["ai"]); }
  function aiPick(path, on) {
    const p = Object.assign({}, aiPicked);
    p[path] = on;
    aiPicked = p;
  }
  // the picked suggestions join the excludes; the list is cleared
  function aiApply() {
    const paths = aiSuggestions.filter(s => aiPicked[s.path]).map(s => s.path);
    if (paths.length === 0) return;
    setConfig({ "excludes": (config.excludes ?? []).concat(paths) });
    aiSuggestions = [];
    aiPicked = ({});
  }
  function forget(snaps) { return job("forget", ["forget"].concat(snaps)); }

  // paths: the folders or files to restore; none restores the whole snapshot
  function restore(snap, paths) {
    const args = ["restore", snap];
    paths.forEach(p => args.push("--include", p));
    return job("restore", args);
  }

  // wl-copy: the shell says it was copied, or why not (it is not installed)
  property bool copied: false
  function copyPassword() {
    if (copyProc.running || revealed === "") return;
    copyProc.command = ["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", revealed];
    copyProc.running = true;
  }

  Process {
    id: copyProc
    stderr: StdioCollector { id: copyErr }
    onExited: code => {
      root.copied = code === 0;
      copiedReset.restart();
      root.done(code === 0, code === 0 ? "Password copied to the clipboard"
        : "Not copied: " + (copyErr.text.trim() || "wl-copy failed (wl-clipboard installed?)").slice(0, 120));
    }
  }

  Timer {
    id: copiedReset
    interval: 2500
    onTriggered: root.copied = false
  }

  function openFolder(path) { Quickshell.execDetached(["xdg-open", path]); }

  // the time since a timestamp, in words
  function agoText(ts) {
    if (!ts) return "never";
    const s = Date.now() / 1000 - ts;
    if (s < 60) return "just now";
    if (s < 3600) return Math.floor(s / 60) + " min ago";
    if (s < 86400) return Math.floor(s / 3600) + " h ago";
    return Math.floor(s / 86400) + " days ago";
  }

  function done(ok, text) {
    status = ok ? "ok" : "error";
    message = text;
    statusReset.restart();
  }

  Timer {
    id: statusReset
    interval: root.messageMs
    onTriggered: { root.status = ""; root.message = ""; }
  }

  Timer {
    id: hideSecret
    interval: root.revealMs
    onTriggered: root.revealed = ""
  }
}
