pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// MihomoService — the single place that mirrors mihomo's state for the shell.
//
// Everything is read from mihomo's external controller through
// scripts/mihomo.sh (JSON out), the same way the other modules read their
// scripts. The bar item (Mihomo.qml) and its popup only render what lives
// here, so the whole shell shares one status poll and one traffic stream.

Singleton {
  id: svc

  // ---- connection / selection ---------------------------------------------
  property bool serviceOn: false
  property bool toggling: false        // a start/stop is in flight (optimistic UI)
  property bool updating: false        // UPDATE running (re-download + re-read)
  property string updateStatus: ""     // "", "ok", "error" — transient result
  property string mode: "rule"
  property string group: Theme.mihomoGroup
  property string current: ""          // node the policy group points at
  property string currentProvider: ""  // provider that node comes from
  property int currentDelay: 0         // last measured ping of the active node (ms)

  // ---- browsing -----------------------------------------------------------
  property var providers: []           // [{name, nodes}]
  property string provider: ""         // provider currently previewed
  property var nodes: []               // [{name, alive, delay}]
  property bool pinging: false
  property string pingStatus: ""       // "", "ok", "error" — transient result

  // ---- add a provider (the form itself lives in the popup) ----------------
  property bool adding: false          // the add form is open
  property bool addBusy: false         // --add-provider in flight
  property string addStatus: ""        // "", "ok", "error" — transient result
  property string addError: ""         // message shown when addStatus is "error"
  property string addName: ""          // form: provider name
  property string addUrl: ""           // form: subscription url

  // ---- traffic (bytes/s + session totals) ---------------------------------
  property real up: 0
  property real down: 0
  property real upTotal: 0
  property real downTotal: 0

  // Number of popups open across all screens; the traffic stream runs only
  // while at least one is visible.
  property int popupsOpen: 0

  onPopupsOpenChanged: {
    if (popupsOpen > 0) {
      if (!trafficProc.running) trafficProc.running = true
    } else {
      trafficProc.running = false
    }
  }

  Component.onCompleted: {
    refreshProviders();
    refreshStatus();
  }

  // ---- helpers ------------------------------------------------------------
  // "🇫🇮 #1 Финляндия | Антиглушилка" -> "🇫🇮 Финляндия"
  function countryOf(name) {
    if (!name) return ""
    var s = name.split("|")[0].trim();
    return s.replace(/#\d+\s*/, "").trim();
  }

  function barLabel() {
    return Theme.iconMihomo + " VPN";
  }

  function humanRate(bytes) {
    if (bytes < 1024) return Math.round(bytes) + " B/s";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB/s";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB/s";
    return (bytes / 1073741824).toFixed(2) + " GB/s";
  }

  function humanSize(bytes) {
    if (bytes < 1024) return Math.round(bytes) + " B";
    if (bytes < 1048576) return (bytes / 1024).toFixed(1) + " KB";
    if (bytes < 1073741824) return (bytes / 1048576).toFixed(1) + " MB";
    if (bytes < 1099511627776) return (bytes / 1073741824).toFixed(2) + " GB";
    return (bytes / 1099511627776).toFixed(2) + " TB";
  }

  // ---- actions ------------------------------------------------------------
  function refreshStatus() { statusProc.running = true; }
  function refreshProviders() { providersProc.running = true; }

  function refreshNodes() {
    if (!serviceOn || provider === "") return;
    nodesProc.command = ["bash", Theme.mihomoScript, "--nodes", provider];
    nodesProc.running = true;
  }

  // Re-read everything the popup can show (status + providers + the current
  // provider's nodes). Called after a subscription update or a settle delay.
  function refreshAll() {
    refreshStatus();
    refreshProviders();
    refreshNodes();
  }

  // ---- update the subscriptions -------------------------------------------
  // Re-downloads every proxy-provider from its URL, then re-reads the state.
  // mihomo.sh writes a log into the mihomo directory when the update fails.
  function runUpdate() {
    if (updating) return;
    updating = true;
    updateStatus = "";
    updateProc.running = true;
  }

  function finishUpdate(text) {
    updating = false;
    var ok = false;
    try { ok = !!JSON.parse(text.trim()).ok; } catch (e) { ok = false; }
    updateStatus = ok ? "ok" : "error";
    updateResultClear.restart();
    refreshAll();
  }

  // ---- open config files in the editor ------------------------------------
  // The file paths are resolved by mihomo.sh (config.yaml for the header gear,
  // the provider's own file for the dots next to a provider).
  function openFile(path) {
    var p = (path || "").trim();
    if (p === "") return;
    Quickshell.execDetached(["kitty", "-e", "nvim", p]);
  }

  function openMihomoConfig() { configPathProc.running = true; }

  function openProviderConfig(name) {
    if (name === "") return;
    providerPathProc.command = ["bash", Theme.mihomoScript, "--path", name];
    providerPathProc.running = true;
  }

  function selectNode(name) {
    if (name === "" || !serviceOn) return;
    selectProc.command = ["bash", Theme.mihomoScript, "--select", name];
    selectProc.running = true;
  }

  function pingNodes() {
    if (!serviceOn || provider === "" || pinging) return;
    pinging = true;
    pingStatus = "";
    pingProc.command = ["bash", Theme.mihomoScript, "--ping", provider];
    pingProc.running = true;
  }

  function finishPing(text) {
    pinging = false;
    var ok = false;
    try { ok = !!JSON.parse(text.trim()).ok; } catch (e) { ok = false; }
    pingStatus = ok ? "ok" : "error";
    pingResultClear.restart();
    refreshNodes();
    refreshStatus();
  }

  // ---- add a provider -----------------------------------------------------
  // The popup's "+ ADD" button opens the form here; SAVE hands name + url to
  // mihomo.sh, which downloads the subscription, saves it under providers/ and
  // registers it in config.yaml before reloading mihomo.
  function beginAdd() {
    addName = "";
    addUrl = "";
    addStatus = "";
    addError = "";
    adding = true;
  }

  function closeAddForm() {
    adding = false;
    addStatus = "";
    addError = "";
    addName = "";
    addUrl = "";
  }

  function addProvider() {
    if (addBusy) return;
    var n = (addName || "").trim();
    var u = (addUrl || "").trim();
    if (n === "" || u === "") {
      addStatus = "error";
      addError = "name and url are required";
      addResultClear.restart();
      return;
    }
    addBusy = true;
    addStatus = "";
    addError = "";
    addProc.command = ["bash", Theme.mihomoScript, "--add-provider", n, u];
    addProc.running = true;
  }

  function finishAdd(text) {
    addBusy = false;
    var ok = false, err = "";
    try {
      var o = JSON.parse(text.trim());
      ok = !!o.ok;
      err = o.error || "";
    } catch (e) { ok = false; }
    if (ok) {
      addStatus = "ok";
      addError = "";
      addName = "";
      addUrl = "";
      refreshProviders();
      refreshStatus();
      addSettle.restart();   // let the reload land, then re-read everything
      addCloseOk.restart();  // …and close the form once the check has shown
    } else {
      addStatus = "error";
      addError = err !== "" ? err : "could not add provider";
      addResultClear.restart();
    }
  }

  function toggleService() {
    if (toggling) return;
    toggling = true;
    serviceOn = !serviceOn;   // optimistic — the switch reacts immediately
    toggleProc.command = ["bash", Theme.mihomoScript, "--toggle"];
    toggleProc.running = true;
  }

  // ---- JSON sinks ---------------------------------------------------------
  function applyStatus(text) {
    try {
      var o = JSON.parse(text.trim());
      var wasOn = serviceOn;
      if (!toggling) serviceOn = o.service === "on";
      mode = o.mode || "rule";
      group = o.group || Theme.mihomoGroup;
      current = o.node || "";
      currentProvider = o.provider || "";
      currentDelay = o.delay || 0;
      if (serviceOn && provider === "" && currentProvider !== "") provider = currentProvider;
      if (serviceOn && !wasOn) refreshProviders();
    } catch (e) {}
  }

  function applyProviders(text) {
    try {
      var list = JSON.parse(text.trim());
      if (!Array.isArray(list)) return;
      providers = list;
      if (list.length === 0) { provider = ""; nodes = []; return; }
      var valid = function (n) {
        return list.some(function (p) { return p.name === n; });
      };
      if (provider === "" || !valid(provider))
        provider = (currentProvider !== "" && valid(currentProvider)) ? currentProvider : list[0].name;
      refreshNodes();
    } catch (e) {}
  }

  function applyNodes(text) {
    try {
      var list = JSON.parse(text.trim());
      nodes = Array.isArray(list) ? list : [];
    } catch (e) { nodes = []; }
  }

  function applyTraffic(line) {
    try {
      var o = JSON.parse(line.trim());
      if (o.up !== undefined) up = o.up;
      if (o.down !== undefined) down = o.down;
      if (o.upTotal !== undefined) upTotal = o.upTotal;
      if (o.downTotal !== undefined) downTotal = o.downTotal;
    } catch (e) {}
  }

  // ---- status poll --------------------------------------------------------
  Process {
    id: statusProc
    command: ["bash", Theme.mihomoScript, "--status"]
    running: true
    stdout: StdioCollector { onStreamFinished: svc.applyStatus(this.text) }
  }

  Timer {
    interval: Theme.mihomoStatusIntervalMs
    running: true
    repeat: true
    onTriggered: svc.refreshStatus()
  }

  // ---- providers ----------------------------------------------------------
  Process {
    id: providersProc
    command: ["bash", Theme.mihomoScript, "--providers"]
    running: true
    stdout: StdioCollector { onStreamFinished: svc.applyProviders(this.text) }
  }

  // ---- nodes of the previewed provider ------------------------------------
  Process {
    id: nodesProc
    stdout: StdioCollector { onStreamFinished: svc.applyNodes(this.text) }
  }

  onProviderChanged: refreshNodes()

  // ---- select -------------------------------------------------------------
  Process {
    id: selectProc
    stdout: StdioCollector { onStreamFinished: { svc.refreshStatus(); selectSettle.restart(); } }
  }

  Timer {
    id: selectSettle
    interval: 350
    onTriggered: svc.refreshNodes()
  }

  // ---- health-check every node --------------------------------------------
  // The script prints {"ok":true,"alive":N} or {"ok":false,…}; the button shows
  // the result briefly (pingResultClear) before returning to its label.
  Process {
    id: pingProc
    stdout: StdioCollector { onStreamFinished: svc.finishPing(this.text) }
    onExited: svc.pinging = false
  }

  Timer {
    id: pingResultClear
    interval: 2500
    onTriggered: svc.pingStatus = ""
  }

  // ---- re-download the subscriptions, then re-read ------------------------
  Process {
    id: updateProc
    command: ["bash", Theme.mihomoScript, "--update"]
    stdout: StdioCollector { onStreamFinished: svc.finishUpdate(this.text) }
    onExited: svc.updating = false
  }

  Timer {
    id: updateResultClear
    interval: 2500
    onTriggered: svc.updateStatus = ""
  }

  // ---- add a provider: fetch + save + register + reload -------------------
  Process {
    id: addProc
    stdout: StdioCollector { onStreamFinished: svc.finishAdd(this.text) }
    onExited: svc.addBusy = false
  }

  Timer {
    id: addSettle
    interval: 900
    onTriggered: svc.refreshAll()
  }

  Timer {
    id: addCloseOk
    interval: 900
    onTriggered: svc.closeAddForm()
  }

  Timer {
    id: addResultClear
    interval: 2500
    onTriggered: svc.addStatus = ""
  }

  // ---- start / stop the service -------------------------------------------
  Process {
    id: toggleProc
    stdout: StdioCollector { onStreamFinished: toggleSettle.restart() }
  }

  Timer {
    id: toggleSettle
    interval: 1500  // mihomo needs a moment to bring TUN + the controller up
    onTriggered: { svc.toggling = false; svc.refreshAll(); }
  }

  // ---- resolve + open config files in the editor --------------------------
  Process {
    id: configPathProc
    command: ["bash", Theme.mihomoScript, "--config-path"]
    stdout: StdioCollector { onStreamFinished: svc.openFile(this.text) }
  }

  Process {
    id: providerPathProc
    stdout: StdioCollector { onStreamFinished: svc.openFile(this.text) }
  }

  // ---- live traffic (only while a popup is open) --------------------------
  Process {
    id: trafficProc
    command: ["bash", Theme.mihomoScript, "--traffic"]
    stdout: SplitParser { onRead: (line) => svc.applyTraffic(line) }
    onExited: { if (svc.popupsOpen > 0) trafficRetry.restart(); }
  }

  Timer {
    id: trafficRetry
    interval: Theme.mihomoTrafficRestartMs
    onTriggered: { if (svc.popupsOpen > 0) trafficProc.running = true; }
  }
}
