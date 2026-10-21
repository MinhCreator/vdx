pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.apps.auth
import qs.config
import "../../kit/reply.js" as Reply

// The cleaner's state (scripts/cleaner.py), shared by its window and its bar
// module. Basic: categories with their size, a pick per category (the safe
// ones picked at first); cleaning empties the picked user ones at once and
// hands the system ones, with their steps in words, to RootService: the
// shell's panel shows them, asks to confirm (and the password the first
// time). AI: Claude's suggestions from a summary of ~, picked ones go to the
// Trash. Options: Shell Manager › Shell apps › Cleaner (ModuleSettings
// "cleaner").
Singleton {
  id: root

  readonly property string script: Paths.scriptsDir + "/cleaner.py"

  // ---- options ----
  function opt(key, fallback) { return ModuleSettings.get("cleaner", key, fallback); }
  readonly property bool confirm: opt("confirm", true)
  readonly property bool aiOn: opt("ai", true)
  readonly property string model: opt("model", "haiku")

  // ---- basic ----
  property var categories: []               // [{id, label, hint, size, root, safe, command}]
  property real total: 0
  property var picked: ({})                 // id -> bool
  property bool scanning: false
  property real scannedAt: 0                // ms; 0: never

  readonly property var pickedUser: categories.filter(c => !c.root && picked[c.id])
  readonly property var pickedRoot: categories.filter(c => c.root && picked[c.id])
  readonly property real pickedSize: pickedUser.concat(pickedRoot).reduce((s, c) => s + c.size, 0)
  readonly property real safeSize: categories.filter(c => !c.root && c.safe).reduce((s, c) => s + c.size, 0)

  function pick(id, on) {
    const p = Object.assign({}, picked);
    p[id] = on;
    picked = p;
  }

  // ---- ai ----
  property var suggestions: []              // [{path, size, days, kind, why, risk}]
  property var aiPicked: ({})               // path -> bool
  property bool analyzing: false
  readonly property var aiChosen: suggestions.filter(s => aiPicked[s.path])
  readonly property real aiSize: aiChosen.reduce((s, x) => s + x.size, 0)

  function aiPick(path, on) {
    const p = Object.assign({}, aiPicked);
    p[path] = on;
    aiPicked = p;
  }

  // ---- actions ----
  property bool busy: false
  property string status: ""                // "" | ok | error
  property string message: ""               // what the last action did, or its error

  function scan() {
    if (scanProc.running) return;
    scanning = true;
    scanProc.running = true;
  }

  // a scan older than a minute is redone (the module's popup, the window)
  function freshen() { if (Date.now() - scannedAt > 60000) scan(); }

  function run(args) {
    busy = true;
    status = "";
    actProc.command = ["python3", script].concat(args);
    actProc.running = true;
  }

  // the picked categories: user ones here, system ones through pkexec
  function clean(ids) {
    if (busy) return;
    const list = ids ?? pickedUser.concat(pickedRoot).map(c => c.id);
    const user = list.filter(id => !(categories.find(c => c.id === id)?.root));
    const sys = list.filter(id => categories.find(c => c.id === id)?.root);
    pendingRoot = sys;
    if (user.length > 0) run(["clean"].concat(user));
    else if (sys.length > 0) plan(sys);
  }
  property var pendingRoot: []

  // the system part: its plan, then RootService runs it after a confirmation
  property var planIds: []
  property real planSize: 0
  function plan(ids) {
    busy = true;
    planIds = ids;
    planProc.command = ["python3", script, "plan"].concat(ids);
    planProc.running = true;
  }

  Process {
    id: planProc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        if (!r.ok) { root.busy = false; root.done(false, r.error); return; }
        root.planSize = r.size;
        if (!RootService.request("Cleaner", "Clean the system", r.steps, r.script, "cleaner")) {
          root.busy = false;
          root.done(false, "another root action is waiting");
        }
      }
    }
  }

  Connections {
    target: RootService
    function onFinished(tag, ok, error) {
      if (tag !== "cleaner") return;
      root.busy = false;
      if (!ok) { root.done(false, error === "cancelled" ? "System part cancelled" : error); root.scan(); return; }
      root.afterSystem = true;
      root.scan();
    }
  }
  // the scan after a system clean tells how much went
  property bool afterSystem: false

  function cleanSafe() { clean(categories.filter(c => !c.root && c.safe && c.size > 0).map(c => c.id)); }

  function analyze() {
    if (analyzing || !aiOn) return;
    analyzing = true;
    status = "";
    aiProc.command = ["python3", script, "ai", model];
    aiProc.running = true;
  }

  function trashChosen() {
    if (busy || aiChosen.length === 0) return;
    run(["trash"].concat(aiChosen.map(s => s.path)));
  }

  function parse(text) {
    return Reply.parse(text, "cleaner.py");
  }

  Timer {
    id: statusReset
    interval: 6000
    onTriggered: { root.status = ""; root.message = ""; }
  }

  function done(ok, text) {
    status = ok ? "ok" : "error";
    message = text;
    statusReset.restart();
  }

  Process {
    id: scanProc
    command: ["python3", root.script, "scan"]
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        root.scanning = false;
        if (!r.ok) { root.done(false, r.error); return; }
        const first = root.categories.length === 0;
        root.categories = r.categories;
        root.total = r.total;
        root.scannedAt = Date.now();
        if (root.afterSystem) {
          root.afterSystem = false;
          const left = r.categories.filter(c => root.planIds.includes(c.id)).reduce((s, c) => s + c.size, 0);
          root.done(true, "Freed " + Format.shortSize(Math.max(0, root.planSize - left)) + " from the system");
        }
        if (first) {
          const p = {};
          for (const c of r.categories) p[c.id] = c.safe && c.size > 0;
          root.picked = p;
        }
      }
    }
  }

  Process {
    id: actProc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        const what = actProc.command[2];
        root.busy = false;
        if (what === "clean" && r.ok && root.pendingRoot.length > 0) {
          root.done(true, "Freed " + Format.shortSize(r.freed) + " · now the system part");
          root.plan(root.pendingRoot);
          root.pendingRoot = [];
          return;
        }
        if (!r.ok) root.done(false, r.error);
        else if (what === "clean") root.done(true, "Freed " + Format.shortSize(r.freed));
        else if (what === "trash") {
          root.done(true, "Moved " + Format.shortSize(r.freed) + " to trash");
          root.suggestions = root.suggestions.filter(s => !root.aiPicked[s.path]);
          root.aiPicked = ({});
        }
        root.scan();
      }
    }
  }

  Process {
    id: aiProc
    stdout: StdioCollector {
      onStreamFinished: {
        const r = root.parse(text);
        root.analyzing = false;
        if (!r.ok) { root.done(false, r.error); return; }
        root.suggestions = r.suggestions;
        const p = {};
        for (const s of r.suggestions) p[s.path] = s.risk === "low";
        root.aiPicked = p;
        if (r.suggestions.length === 0) root.done(true, "Nothing Claude would remove");
      }
    }
  }
}
