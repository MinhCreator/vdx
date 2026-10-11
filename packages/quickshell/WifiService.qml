pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// WifiService — the single place that mirrors NetworkManager's wifi state for
// the shell. Backed by scripts/wifi.sh (nmcli -> JSON out). The bar item
// (Wifi.qml) and its popup only render what lives here.

Singleton {
  id: svc

  // ---- radio / link -------------------------------------------------------
  property bool radioOn: false
  property bool toggling: false
  property string linkState: "unavailable"  // connected | connecting | disconnected | unavailable
  property string ssid: ""
  property string device: ""                // "wlan0", "eth0", …

  readonly property bool connected: radioOn && linkState === "connected"

  // ---- browsing -----------------------------------------------------------
  property var networks: []              // every visible AP, [{ssid,signal,secure,active,saved,…}]

  // The two subsections of the networks list. Known = visible APs whose SSID
  // matches a saved profile (i.e. we can join without asking for a password).
  // Other = everything else that is currently in range.
  readonly property var knownNetworks: {
    var out = [];
    for (var i = 0; i < networks.length; i++) if (networks[i].saved) out.push(networks[i]);
    return out;
  }
  readonly property var otherNetworks: {
    var out = [];
    for (var i = 0; i < networks.length; i++) if (!networks[i].saved) out.push(networks[i]);
    return out;
  }

  // ---- info panel ---------------------------------------------------------
  property string ipAddress: ""
  property string gateway: ""
  property real pingMs: 0
  property int packetLoss: 0              // 0..100

  // ---- DNS provider -------------------------------------------------------
  property string dnsMode: "dhcp"         // dhcp | cloudflare | google | custom
  property string dnsCustomValue: ""      // last known custom value (shown when mode=custom)
  property string dnsFormValue: ""        // input field while editing custom
  property bool dnsBusy: false
  property string dnsStatus: ""           // "", "ok", "error"
  property string dnsError: ""

  // ---- QR share -----------------------------------------------------------
  property string qrData: ""              // base64 PNG (data URL body)
  property bool qrBusy: false
  property string qrError: ""
  property string qrSsid: ""              // ssid shown in the QR overlay
  property string qrPassword: ""          // plaintext psk ("" for open networks)
  property string qrCopyStatus: ""        // "", "ok", "error"

  // ---- speedtest ----------------------------------------------------------
  property bool speedtestBusy: false
  property real speedtestDown: 0          // Mbps
  property real speedtestUp: 0            // Mbps
  property real speedtestPing: 0          // ms (Cloudflare resolver)
  property real speedtestJitter: 0        // ms
  property real speedtestDuration: 0      // s
  property string speedtestIp: ""         // public IPv4
  property string speedtestServer: ""     // "speed.cloudflare.com"
  property string speedtestError: ""

  // ---- overlays -----------------------------------------------------------
  property string view: "list"            // "list" | "password" | "qr" | "speedtest" | "dns-custom"
  property string target: ""              // ssid the overlay is about

  // ---- actions in flight --------------------------------------------------
  property string connectingSsid: ""
  property string connectStatus: ""
  property string connectError: ""
  property string password: ""            // form: password field

  // ---- traffic ------------------------------------------------------------
  property real up: 0
  property real down: 0
  property real upTotal: 0
  property real downTotal: 0

  // Number of popups open across all screens; ping + traffic streams run only
  // while at least one is visible.
  property int popupsOpen: 0

  onPopupsOpenChanged: {
    if (popupsOpen > 0) {
      if (!trafficProc.running) trafficProc.running = true;
      if (!pingProc.running) pingProc.running = true;
    } else {
      trafficProc.running = false;
      pingProc.running = false;
    }
  }

  onConnectedChanged: {
    if (connected) {
      refreshDns();
    } else {
      ipAddress = "";
      gateway = "";
      pingMs = 0;
      packetLoss = 0;
    }
  }

  Component.onCompleted: refreshStatus()

  // ---- helpers ------------------------------------------------------------
  function barLabel() {
    if (connected) {
      var s = ssid;
      if (s.length > 14) s = s.substring(0, 13) + Theme.ellipsis;
      return Theme.iconWifi + "  " + s;
    }
    return Theme.iconWifi + "  Disconnected";
  }

  function pingText() { return pingMs > 0 ? Math.round(pingMs) + " ms" : "—"; }
  function lossText() { return connected ? packetLoss + " %" : "—"; }

  function speedDownText() {
    return speedtestDown > 0 ? Number(speedtestDown).toFixed(2) + " Mbps" : "—";
  }
  function speedUpText() {
    return speedtestUp > 0 ? Number(speedtestUp).toFixed(2) + " Mbps" : "—";
  }
  function speedPingText() {
    return speedtestPing > 0 ? Number(speedtestPing).toFixed(0) + " ms" : "—";
  }
  function speedJitterText() {
    return speedtestJitter > 0 ? Number(speedtestJitter).toFixed(1) + " ms" : "—";
  }
  function speedDurationText() {
    return speedtestDuration > 0 ? Number(speedtestDuration).toFixed(1) + " s" : "—";
  }

  function parseOk(text) {
    try { return JSON.parse(text.trim()); } catch (e) { return { ok: false }; }
  }

  // ---- refresh ------------------------------------------------------------
  function refreshStatus() { statusProc.running = true; }
  function refreshNetworks() { if (radioOn) networksProc.running = true; }
  function refreshPing() { if (radioOn && popupsOpen > 0) pingProc.running = true; }

  function refreshDns() {
    if (!connected) {
      dnsMode = "dhcp";
      dnsCustomValue = "";
      return;
    }
    dnsGetProc.running = true;
  }

  function refreshAll() {
    refreshStatus();
    refreshNetworks();
    refreshDns();
    refreshPing();
  }

  function popupOpened() {
    refreshAll();
    scan();
  }

  function closeView() {
    view = "list";
    target = "";
    password = "";
    connectError = "";
    connectStatus = "";
    qrData = "";
    qrError = "";
    qrSsid = "";
    qrPassword = "";
    qrCopyStatus = "";
    dnsFormValue = "";
    dnsError = "";
  }

  function resetSpeedtest() {
    if (speedtestProc.running) speedtestProc.running = false;
    speedtestBusy = false;
    speedtestDown = 0;
    speedtestUp = 0;
    speedtestPing = 0;
    speedtestJitter = 0;
    speedtestDuration = 0;
    speedtestIp = "";
    speedtestServer = "";
    speedtestError = "";
  }

  function resetView() {
    closeView();
    resetSpeedtest();
  }

  // ---- scan ---------------------------------------------------------------
  function scan() {
    if (scanProc.running || !radioOn) return;
    scanProc.running = true;
  }

  function finishScan() {
    refreshNetworks();
    refreshStatus();
  }

  // ---- radio --------------------------------------------------------------
  function toggleRadio() {
    if (toggling) return;
    toggling = true;
    radioOn = !radioOn;
    if (!radioOn) {
      networks = [];
      resetView();
    }
    radioProc.command = ["bash", Theme.wifiScript, "--radio", radioOn ? "on" : "off"];
    radioProc.running = true;
  }

  // ---- connect ------------------------------------------------------------
  // Secured and unknown -> the password form first; saved / open -> connect
  // straight away.
  function connectTo(name, secure, isSaved) {
    if (name === "" || !radioOn || connectingSsid !== "") return;
    if (connected && name === ssid) return;
    if (secure && !isSaved) { openPassword(name); return; }
    doConnect(name, "");
  }

  function doConnect(name, pw) {
    connectingSsid = name;
    connectStatus = "";
    connectError = "";
    connectProc.environment = { WIFI_PASS: pw };
    connectProc.command = ["bash", Theme.wifiScript, "--connect", name];
    connectProc.running = true;
  }

  function finishConnect(text) {
    connectingSsid = "";
    connectProc.environment = ({});
    var o = parseOk(text);
    if (o.ok) {
      connectStatus = "ok";
      connectError = "";
      password = "";
      if (view === "password") passwordCloseOk.restart();
    } else {
      connectStatus = "error";
      connectError = o.error || "could not connect";
    }
    connectResultClear.restart();
    refreshAll();
    settle.restart();
  }

  function openPassword(name) {
    target = name;
    password = "";
    connectStatus = "";
    connectError = "";
    view = "password";
  }

  function submitPassword() {
    if (connectingSsid !== "") return;
    if (password === "") {
      connectStatus = "error";
      connectError = "password is required";
      connectResultClear.restart();
      return;
    }
    doConnect(target, password);
  }

  // ---- QR share -----------------------------------------------------------
  function openQr() {
    if (!connected || ssid === "") return;
    qrData = "";
    qrError = "";
    qrBusy = true;
    qrSsid = ssid;
    qrPassword = "";
    qrCopyStatus = "";
    qrProc.command = ["bash", Theme.wifiScript, "--qr", ssid];
    qrProc.running = true;
    view = "qr";
  }

  function applyQr(text) {
    qrBusy = false;
    var o = parseOk(text);
    if (o && o.ok && o.data) {
      qrData = o.data;
      qrError = "";
      qrSsid = (o.ssid !== undefined && o.ssid !== "") ? o.ssid : ssid;
      qrPassword = (o.password !== undefined) ? o.password : "";
    } else {
      qrData = "";
      qrError = (o && o.error) ? o.error : "could not build QR";
      qrSsid = "";
      qrPassword = "";
    }
  }

  function closeQr() {
    view = "list";
    qrData = "";
    qrError = "";
    qrSsid = "";
    qrPassword = "";
    qrCopyStatus = "";
  }

  // The popup never touches the clipboard itself — it asks the service, which
  // copies the key (or the SSID for an open network) and flashes the result.
  function copyCredentials() {
    var text = qrPassword !== "" ? qrPassword : qrSsid;
    if (text === "") {
      qrCopyStatus = "error";
    } else {
      Quickshell.clipboardText = text;
      qrCopyStatus = "ok";
    }
    qrCopyClear.restart();
  }

  // ---- speedtest ----------------------------------------------------------
  // The overlay starts the test immediately; both directions run back to back
  // in a single `--speedtest` call, so the popup stays open the whole time.
  function openSpeedtest() {
    if (!connected || speedtestBusy) return;
    resetSpeedtest();
    speedtestBusy = true;
    view = "speedtest";
    speedtestProc.command = ["bash", Theme.wifiScript, "--speedtest"];
    speedtestProc.running = true;
  }

  function finishSpeedtest(text) {
    speedtestBusy = false;
    var o = parseOk(text);
    if (o && o.ok) {
      // curl reports bytes/sec; 1 Mbps = 125000 B/s
      speedtestDown = (o.down || 0) / 125000;
      speedtestUp = (o.up || 0) / 125000;
      speedtestPing = o.ping || 0;
      speedtestJitter = o.jitter || 0;
      speedtestDuration = o.duration || 0;
      speedtestIp = o.ip || "";
      speedtestServer = o.server || "";
      speedtestError = "";
    } else {
      speedtestError = (o && o.error) ? o.error : "speedtest failed";
    }
  }

  function closeSpeedtest() {
    view = "list";
    resetSpeedtest();
  }

  // ---- DNS provider -------------------------------------------------------
  function setDns(mode) {
    if (dnsBusy) return;
    if (mode === "custom") { openCustomDns(); return; }
    dnsBusy = true;
    dnsStatus = "";
    dnsError = "";
    dnsSetProc.command = ["bash", Theme.wifiScript, "--dns", "set", mode];
    dnsSetProc.running = true;
  }

  function openCustomDns() {
    dnsFormValue = dnsCustomValue !== "" ? dnsCustomValue : "";
    dnsError = "";
    view = "dns-custom";
  }

  function submitCustomDns() {
    if (dnsBusy) return;
    var v = (dnsFormValue || "").trim();
    if (v === "") { dnsError = "servers are required"; return; }
    dnsBusy = true;
    dnsStatus = "";
    dnsError = "";
    dnsSetProc.command = ["bash", Theme.wifiScript, "--dns", "set", "custom", v];
    dnsSetProc.running = true;
  }

  function finishDnsSet(text) {
    dnsBusy = false;
    var o = parseOk(text);
    if (o && o.ok) {
      dnsStatus = "ok";
      dnsError = "";
      refreshDns();
      if (view === "dns-custom") dnsCloseOk.restart();
    } else {
      dnsStatus = "error";
      dnsError = (o && o.error) ? o.error : "could not set DNS";
    }
    dnsResultClear.restart();
  }

  // ---- JSON sinks ---------------------------------------------------------
  function applyStatus(text) {
    try {
      var o = JSON.parse(text.trim());
      if (!toggling) radioOn = o.radio === "on";
      ssid = o.ssid || "";
      linkState = o.state || "unavailable";
      device = o.device || "";
      ipAddress = o.ip || "";
      gateway = o.gateway || "";
    } catch (e) {}
  }

  function applyNetworks(text) {
    try {
      var list = JSON.parse(text.trim());
      networks = Array.isArray(list) ? list : [];
    } catch (e) { networks = []; }
  }

  function applyPing(text) {
    try {
      var o = JSON.parse(text.trim());
      if (o && o.ok) {
        pingMs = o.ping || 0;
        packetLoss = (o.loss === undefined ? 0 : o.loss) | 0;
      } else {
        pingMs = 0;
        packetLoss = 0;
      }
    } catch (e) {
      pingMs = 0;
      packetLoss = 0;
    }
  }

  function applyDnsGet(text) {
    try {
      var o = JSON.parse(text.trim());
      dnsMode = o.mode || "dhcp";
      dnsCustomValue = (dnsMode === "custom") ? (o.dns || "") : "";
    } catch (e) {}
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
    command: ["bash", Theme.wifiScript, "--status"]
    stdout: StdioCollector { onStreamFinished: svc.applyStatus(this.text) }
  }

  Timer {
    interval: Theme.wifiStatusIntervalMs
    running: true
    repeat: true
    onTriggered: svc.refreshStatus()
  }

  // ---- visible networks ---------------------------------------------------
  Process {
    id: networksProc
    command: ["bash", Theme.wifiScript, "--list"]
    stdout: StdioCollector { onStreamFinished: svc.applyNetworks(this.text) }
  }

  // Re-read once NetworkManager has actually changed state.
  Timer {
    id: settle
    interval: 800
    onTriggered: svc.refreshAll()
  }

  // ---- ping / packet loss -------------------------------------------------
  Process {
    id: pingProc
    command: ["bash", Theme.wifiScript, "--ping"]
    stdout: StdioCollector { onStreamFinished: svc.applyPing(this.text) }
    onExited: { if (svc.popupsOpen > 0) pingRetry.restart(); }
  }

  Timer {
    id: pingRetry
    interval: Theme.wifiPingIntervalMs
    onTriggered: { if (svc.popupsOpen > 0) pingProc.running = true; }
  }

  // ---- speedtest ----------------------------------------------------------
  Process {
    id: speedtestProc
    stdout: StdioCollector { onStreamFinished: svc.finishSpeedtest(this.text) }
    onExited: svc.speedtestBusy = false
  }

  // ---- QR ----------------------------------------------------------------
  Process {
    id: qrProc
    stdout: StdioCollector { onStreamFinished: svc.applyQr(this.text) }
    onExited: svc.qrBusy = false
  }

  Timer {
    id: qrCopyClear
    interval: 2500
    onTriggered: svc.qrCopyStatus = ""
  }

  // ---- DNS ---------------------------------------------------------------
  Process {
    id: dnsGetProc
    command: ["bash", Theme.wifiScript, "--dns", "get"]
    stdout: StdioCollector { onStreamFinished: svc.applyDnsGet(this.text) }
  }

  Process {
    id: dnsSetProc
    stdout: StdioCollector { onStreamFinished: svc.finishDnsSet(this.text) }
    onExited: svc.dnsBusy = false
  }

  Timer {
    id: dnsResultClear
    interval: 2500
    onTriggered: svc.dnsStatus = ""
  }

  Timer {
    id: dnsCloseOk
    interval: 900
    onTriggered: { if (svc.view === "dns-custom") svc.view = "list"; }
  }

  // ---- rescan -------------------------------------------------------------
  Process {
    id: scanProc
    command: ["bash", Theme.wifiScript, "--scan"]
    stdout: StdioCollector { onStreamFinished: svc.finishScan() }
  }

  // ---- radio --------------------------------------------------------------
  Process {
    id: radioProc
    stdout: StdioCollector { onStreamFinished: radioSettle.restart() }
  }

  Timer {
    id: radioSettle
    interval: 1500
    onTriggered: {
      svc.toggling = false;
      svc.refreshAll();
      if (svc.radioOn) svc.scan();
    }
  }

  // ---- connect ------------------------------------------------------------
  Process {
    id: connectProc
    stdout: StdioCollector { onStreamFinished: svc.finishConnect(this.text) }
    onExited: svc.connectingSsid = ""
  }

  Timer {
    id: connectResultClear
    interval: 2500
    onTriggered: svc.connectStatus = ""
  }

  Timer {
    id: passwordCloseOk
    interval: 900
    onTriggered: svc.closeView()
  }

  // ---- live traffic -------------------------------------------------------
  Process {
    id: trafficProc
    command: ["bash", Theme.wifiScript, "--traffic"]
    stdout: SplitParser { onRead: (line) => svc.applyTraffic(line) }
    onExited: { if (svc.popupsOpen > 0) trafficRetry.restart(); }
  }

  Timer {
    id: trafficRetry
    interval: Theme.wifiTrafficRestartMs
    onTriggered: { if (svc.popupsOpen > 0) trafficProc.running = true; }
  }
}