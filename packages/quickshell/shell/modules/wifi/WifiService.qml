pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Wi-Fi state and actions on top of scripts/wifi.sh. The bar module and the
// popup only read these properties and call these functions.
Singleton {
  id: root

  // ---- link ----------------------------------------------------------------
  property bool radioOn: false
  property bool toggling: false                // radio switch in flight
  property string linkState: "unavailable"     // connected | connecting | disconnected | unavailable
  property string ssid: ""
  property string ipAddress: ""
  property string gateway: ""
  readonly property bool connected: radioOn && linkState === "connected"

  property var networks: []                    // see `wifi.sh --list`

  // ---- popup ---------------------------------------------------------------
  property bool popupOpen: false
  property string view: "list"                 // list | password | speedtest
  property var selected: null                  // network of the password view

  property string password: ""
  property string connectingSsid: ""
  property string connectStatus: ""            // "" | ok | error
  property string connectError: ""

  // ---- DNS -----------------------------------------------------------------
  property var dnsProviders: []                // [{label, servers}], dns_providers.json
  property bool dnsAuto: true
  property string dnsServers: ""
  property bool dnsBusy: false
  property string dnsStatus: ""                // "" | ok | error
  property string dnsError: ""
  readonly property var dnsProvider: dnsProviders.find(p => dnsAuto ? p.servers === "" : p.servers === dnsServers) ?? null
  readonly property string dnsLabel: dnsProvider ? dnsProvider.label : "CUSTOM"

  // ---- link quality (measured only while the popup is open) ----------------
  property real pingMs: 0
  property real packetLoss: 0
  property real up: 0
  property real down: 0
  property real upTotal: 0
  property real downTotal: 0

  // ---- speedtest -----------------------------------------------------------
  property bool speedtestBusy: false
  property var speedtest: null                 // see `wifi.sh --speedtest`
  property string speedtestError: ""

  // ---- lifecycle -----------------------------------------------------------
  function popupShown() {
    popupOpen = true;
    refresh();
    scan();
  }

  function popupHidden() {
    popupOpen = false;
    showList();
  }

  onPopupOpenChanged: trafficProc.running = popupOpen
  onConnectedChanged: { refreshNetworks(); refreshDns(); }
  onSsidChanged: { refreshNetworks(); refreshDns(); }

  Component.onCompleted: refreshStatus()

  // ---- views ---------------------------------------------------------------
  function showList() {
    view = "list";
    selected = null;
    password = "";
    connectStatus = "";
    connectError = "";
    dnsError = "";
    stopSpeedtest();
  }

  function showSpeedtest() {
    view = "speedtest";
    speedtest = null;
    speedtestError = "";
    speedtestBusy = true;
    speedtestTimeout.restart();
    run(speedtestProc, ["--speedtest"]);
  }

  // ---- actions -------------------------------------------------------------
  function toggleRadio() {
    if (toggling) return;
    toggling = true;
    radioOn = !radioOn;
    if (!radioOn) {
      networks = [];
      showList();
    }
    run(radioProc, ["--radio", radioOn ? "on" : "off"]);
  }

  function connectTo(net) {
    if (!radioOn || connectingSsid !== "" || (connected && net.ssid === ssid)) return;
    if (net.secure && !net.saved) {
      selected = net;
      password = "";
      view = "password";
      return;
    }
    connect(net.ssid, "");
  }

  function submitPassword() {
    if (connectingSsid === "" && password !== "") connect(selected.ssid, password);
  }

  function setDns(servers) {
    if (!connected || dnsBusy) return;
    dnsBusy = true;
    dnsStatus = "";
    dnsError = "";
    run(dnsSetProc, ["--dns", "set", servers]);
  }

  function scan() {
    if (radioOn && !scanProc.running) scanProc.running = true;
  }

  // ---- internals -----------------------------------------------------------
  function run(proc, args) {
    proc.command = ["bash", Theme.wifiScript].concat(args);
    proc.running = true;
  }

  function parse(text) {
    try { return JSON.parse(text); } catch (e) { return null; }
  }

  function refresh() {
    refreshStatus();
    refreshNetworks();
    refreshDns();
  }

  function refreshStatus() { statusProc.running = true; }
  function refreshNetworks() { if (radioOn) networksProc.running = true; }
  function refreshDns() { if (connected) dnsGetProc.running = true; }

  function connect(name, pw) {
    connectingSsid = name;
    connectStatus = "";
    connectError = "";
    connectProc.environment = { WIFI_PASS: pw };
    run(connectProc, ["--connect", name]);
  }

  function stopSpeedtest() {
    speedtestBusy = false;
    speedtestProc.running = false;
    speedtestTimeout.stop();
  }

  // ---- polling -------------------------------------------------------------
  Timer {
    interval: Theme.wifiStatusIntervalMs
    running: true
    repeat: true
    onTriggered: root.refreshStatus()
  }

  // Signal levels come from NM's scan cache: re-read it while the popup is
  // open and rescan every fourth tick so the other access points update too.
  Timer {
    property int tick: 0

    interval: Theme.wifiStatusIntervalMs
    running: root.popupOpen && root.radioOn
    repeat: true
    onTriggered: ++tick % 4 === 0 ? root.scan() : root.refreshNetworks()
  }

  Timer {
    interval: Theme.wifiPingIntervalMs
    running: root.popupOpen && root.connected
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!pingProc.running) pingProc.running = true
  }

  Timer {
    id: trafficRestart
    interval: Theme.wifiTrafficRestartMs
    onTriggered: if (root.popupOpen) trafficProc.running = true
  }

  // ---- transient results -----------------------------------------------------
  Timer {
    id: radioSettle
    interval: 1500
    onTriggered: {
      root.toggling = false;
      root.refresh();
      root.scan();
    }
  }

  Timer {
    id: connectClear
    interval: Theme.popupStatusMs
    onTriggered: {
      if (root.connectStatus === "ok" && root.view === "password") root.showList();
      root.connectStatus = "";
    }
  }

  Timer {
    id: dnsClear
    interval: Theme.popupStatusMs
    onTriggered: root.dnsStatus = ""
  }

  Timer {
    id: speedtestTimeout
    interval: Theme.wifiSpeedtestTimeoutMs
    onTriggered: {
      root.stopSpeedtest();
      root.speedtestError = "timeout";
    }
  }

  // ---- processes -----------------------------------------------------------
  Process {
    id: statusProc
    command: ["bash", Theme.wifiScript, "--status"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        if (!o) return;
        if (!root.toggling) root.radioOn = o.radio === "on";
        root.linkState = o.state;
        root.ssid = o.ssid;
        root.ipAddress = o.ip;
        root.gateway = o.gateway;
      }
    }
  }

  Process {
    id: networksProc
    command: ["bash", Theme.wifiScript, "--list"]
    stdout: StdioCollector {
      onStreamFinished: root.networks = root.parse(text) ?? []
    }
  }

  Process {
    id: scanProc
    command: ["bash", Theme.wifiScript, "--scan"]
    stdout: StdioCollector {
      onStreamFinished: root.refreshNetworks()
    }
  }

  Process {
    id: radioProc
    stdout: StdioCollector {
      onStreamFinished: radioSettle.restart()
    }
  }

  Process {
    id: connectProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.connectingSsid = "";
        connectProc.environment = {};
        root.connectStatus = o?.ok ? "ok" : "error";
        root.connectError = o?.ok ? "" : (o?.error ?? "could not connect");
        if (o?.ok) root.password = "";
        connectClear.restart();
        root.refreshStatus();
        root.refreshNetworks();
      }
    }
  }

  Process {
    id: dnsGetProc
    command: ["bash", Theme.wifiScript, "--dns", "get"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        if (!o?.ok) return;
        root.dnsAuto = o.auto;
        root.dnsServers = o.servers;
      }
    }
  }

  Process {
    id: dnsSetProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.dnsBusy = false;
        root.dnsStatus = o?.ok ? "ok" : "error";
        root.dnsError = o?.ok ? "" : (o?.error ?? "could not set DNS");
        dnsClear.restart();
        root.refreshDns();
      }
    }
  }

  Process {
    id: pingProc
    command: ["bash", Theme.wifiScript, "--ping"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.pingMs = o?.ok ? o.ping : 0;
        root.packetLoss = o?.ok ? o.loss : 0;
      }
    }
  }

  Process {
    id: speedtestProc
    stdout: StdioCollector {
      onStreamFinished: {
        if (!root.speedtestBusy) return;   // cancelled
        const o = root.parse(text);
        root.stopSpeedtest();
        root.speedtest = o?.ok ? o : null;
        root.speedtestError = o?.ok ? "" : (o?.error ?? "speedtest failed");
      }
    }
  }

  Process {
    id: trafficProc
    command: ["bash", Theme.wifiScript, "--traffic"]
    stdout: SplitParser {
      onRead: line => {
        const o = root.parse(line);
        if (!o) return;
        root.up = o.up;
        root.down = o.down;
        root.upTotal = o.upTotal;
        root.downTotal = o.downTotal;
      }
    }
    onExited: if (root.popupOpen) trafficRestart.restart()
  }

  FileView {
    path: Quickshell.shellDir + "/modules/wifi/dns_providers.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.dnsProviders = root.parse(text()) ?? []
  }
}
