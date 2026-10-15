pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.apps.auth
import qs.config

// The package manager's state (scripts/packages.py), shared by its window and
// its bar module: pending updates from the repos and the AUR, the installed
// packages (the picked ones can be removed), pacman's cache with its versions,
// and the rollback of the last upgrade. Updating opens a terminal running
// `yay -Syu --sudo pkexec`: yay shows the AUR builds there, and the password
// comes from the auth panel. Removing and rolling back go to RootService,
// which shows the steps first.
Singleton {
  id: root

  readonly property string script: Theme.scriptsDir + "/packages.py"

  // ---- updates ----
  property var pacman: []                   // [{name, from, to}]
  property var aur: []
  property string aurError: ""
  property bool checking: false
  property real checkedAt: 0                // ms; 0: never
  // ---- options (Shell Manager › Shell apps, ModuleSettings "packages") ----
  function opt(key, fallback) { return ModuleSettings.get("packages", key, fallback); }
  readonly property bool aurOn: opt("aur", true)
  readonly property bool confirm: opt("confirm", true)
  readonly property string defaultUpdate: "if command -v yay >/dev/null; then yay -Syu --sudo pkexec; else pkexec pacman -Syu; fi"

  readonly property int count: pacman.length + (aurOn ? aur.length : 0)
  // every pending update in one list: {name, from, to, desc, aur}
  readonly property var pending: pacman.map(p => Object.assign({ aur: false }, p))
      .concat(aurOn ? aur.map(p => Object.assign({ aur: true }, p)) : [])
  property var updPicked: ({})              // name -> bool
  readonly property var pickedUpdates: pending.filter(p => updPicked[p.name] === true)

  // ---- installed ----
  property var installed: []                // [{name, version, desc, size, aur, explicit, apps}]
  property bool loading: false
  property var picked: ({})                 // name -> bool
  readonly property var pickedNames: Object.keys(picked).filter(n => picked[n])
  readonly property real pickedSize: installed.filter(p => picked[p.name]).reduce((s, p) => s + p.size, 0)

  // ---- cache ----
  property var cache: []                    // [{name, installed, versions: [{version, file, size, date}]}]
  property var lastUpdate: null             // {date, packages: [{name, from, to, file}], missing: [{name, from}]}
  readonly property int rollbackCount: lastUpdate?.packages?.length ?? 0

  // ---- actions ----
  property bool busy: false
  property string status: ""                // "" | ok | error
  property string message: ""

  function size(bytes) {
    if (bytes < 1048576) return Math.round(bytes / 1024) + " KB";
    if (bytes < 1073741824) return Math.round(bytes / 1048576) + " MB";
    return (bytes / 1073741824).toFixed(1) + " GB";
  }

  function pick(name, on) { pickMany([name], on); }

  function pickMany(names, on) {
    const p = Object.assign({}, picked);
    for (const n of names) p[n] = on;
    picked = p;
  }

  function pickUpdate(name, on) {
    const p = Object.assign({}, updPicked);
    p[name] = on;
    updPicked = p;
  }

  function pickAllUpdates(on) {
    const p = {};
    for (const u of pending) p[u.name] = on;
    updPicked = p;
  }

  function parse(text) {
    try { return JSON.parse(text); } catch (e) { return { ok: false, error: "bad reply from packages.py" }; }
  }

  // ---- checks ----
  function check() {
    if (checking) return;
    checking = true;
    checkProc.running = true;
  }

  function loadInstalled() {
    if (installedProc.running) return;
    loading = true;
    installedProc.running = true;
  }

  function loadCache() {
    if (cacheProc.running) return;
    cacheProc.running = true;
  }

  function loadLast() {
    if (lastProc.running) return;
    lastProc.running = true;
  }

  // the whole view again. The update check runs when forced (the refresh
  // button), or on opening when the option is on and the last check is old
  function freshen(force) {
    if (force || (opt("checkOnOpen", true) && Date.now() - checkedAt > 600000)) check();
    loadInstalled();
    loadCache();
    loadLast();
  }

  Component.onCompleted: check()

  // the repos and the AUR move on: check again at the chosen interval (0: off)
  Timer {
    interval: root.opt("interval", 30) * 60000
    running: root.opt("interval", 30) > 0
    repeat: true
    onTriggered: root.check()
  }

  // ---- actions ----
  // the update runs in a terminal: yay reviews the AUR builds there and asks
  // for the password through the auth panel (pkexec). The command is the
  // option "updateCommand"; empty means the default
  function updateAll() {
    const cmd = (opt("updateCommand", defaultUpdate) ?? "").trim() || defaultUpdate;
    Quickshell.execDetached(["kitty", "-e", "bash", "-c",
      cmd + "; echo; read -rp 'press Enter to close ' _"]);
  }

  // the picked updates only: `yay -Sy` refreshes the databases, then installs
  // those names. The others stay pending, so the system may end up partly
  // upgraded — the window says so.
  function updatePicked() {
    if (pickedUpdates.length === 0) return;
    Quickshell.execDetached(["kitty", "-e", "bash", "-c",
      "yay -Sy --needed --sudo pkexec \"$@\"; echo; read -rp 'press Enter to close ' _",
      "bash"].concat(pickedUpdates.map(p => p.name)));
    updPicked = ({});
  }

  function removePicked() {
    if (busy || pickedNames.length === 0) return;
    busy = true;
    status = "";
    planProc.command = ["python3", root.script, "plan-remove"].concat(pickedNames);
    planProc.plan = { tag: "packages-remove", title: "Remove packages" };
    planProc.running = true;
  }

  function rollback(files) {
    if (busy || files.length === 0) return;
    busy = true;
    status = "";
    planProc.command = ["python3", root.script, "plan-rollback"].concat(files);
    planProc.plan = { tag: "packages-rollback", title: "Roll back" };
    planProc.running = true;
  }

  function rollbackLast() { rollback((lastUpdate?.packages ?? []).map(p => p.file)); }

  function done(ok, text) {
    status = ok ? "ok" : "error";
    message = text;
    statusReset.restart();
  }

  Timer {
    id: statusReset
    interval: 6000
    onTriggered: { root.status = ""; root.message = ""; }
  }

  // the plan's steps go to RootService, which shows them and runs the script
  Process {
    id: planProc
    property var plan: null
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (!r.ok) { root.busy = false; root.done(false, r.error); return; }
        if (!RootService.request("Packages", planProc.plan.title, r.steps, r.script, planProc.plan.tag)) {
          root.busy = false;
          root.done(false, "another root action is waiting");
        }
      }
    }
  }

  Connections {
    target: RootService
    function onFinished(tag, ok, error) {
      if (!tag.startsWith("packages-")) return;
      root.busy = false;
      if (!ok) { root.done(false, error === "cancelled" ? "cancelled" : error); return; }
      if (tag === "packages-remove") root.picked = ({});
      root.done(true, tag === "packages-remove" ? "Removed" : "Rolled back");
      root.freshen();
    }
  }

  Process {
    id: checkProc
    command: ["python3", root.script, "updates"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        root.checking = false;
        if (!r.ok) { root.done(false, r.error); return; }
        root.pacman = r.pacman;
        root.aur = r.aur;
        root.aurError = r.aurError;
        root.checkedAt = Date.now();
      }
    }
  }

  Process {
    id: installedProc
    command: ["python3", root.script, "installed"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        root.loading = false;
        if (!r.ok) { root.done(false, r.error); return; }
        root.installed = r.packages;
      }
    }
  }

  Process {
    id: cacheProc
    command: ["python3", root.script, "cache"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (!r.ok) { root.done(false, r.error); return; }
        root.cache = r.packages;
      }
    }
  }

  Process {
    id: lastProc
    command: ["python3", root.script, "last-update"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (!r.ok) { root.done(false, r.error); return; }
        root.lastUpdate = r;
      }
    }
  }
}
