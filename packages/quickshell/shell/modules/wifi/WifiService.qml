pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../../kit/reply.js" as Reply

// Wi-Fi state and actions on top of scripts/wifi.sh. The bar module and the
// popup only read these properties and call these functions.
Singleton {
  id: root

  // ---- tuning ----
  readonly property int statusPollMs: 5000     // while the popup is open
  readonly property int idlePollMs: 20000      // closed: the face (NM changes come by --listen)
  readonly property int changeMs: 500         // the least gap between two re-reads on events
  readonly property int pingPollMs: 3000
  readonly property int trafficRestartMs: 2000
  readonly property int speedtestTimeoutMs: 60000
  readonly property int barMaxLength: 14  // the SSID on the bar, in characters
  readonly property string script: Paths.scriptsDir + "/wifi.sh"

  // ---- link ----
  property bool radioOn: false
  property bool toggling: false                // radio switch in flight
  property string radioError: ""
  property string linkState: "unavailable"     // connected | connecting | disconnected | unavailable
  property string ssid: ""
  property string ipAddress: ""
  property string gateway: ""
  property string statusError: ""
  readonly property bool connected: radioOn && linkState === "connected"

  property var networks: []                    // see `wifi.sh --list`
  property string networkError: ""
  property bool scanning: false
  property string scanError: ""

  // ---- popup ----
  property bool popupOpen: false
  property string view: "list"                 // list | password
  property var selected: null                  // network of the password view

  property string password: ""
  property string connectingSsid: ""
  property string connectStatus: ""            // "" | ok | error
  property string connectError: ""

  // ---- DNS ----
  property var dnsProviders: []                // [{label, servers}], dns_providers.json
  property bool dnsAuto: true
  property string dnsServers: ""
  property bool dnsBusy: false
  property string dnsError: ""
  readonly property var dnsProvider: dnsProviders.find(p => dnsAuto ? p.servers === "" : p.servers === dnsServers) ?? null
  readonly property string dnsLabel: dnsProvider ? dnsProvider.label : "CUSTOM"

  // ---- link quality (measured only while the popup is open) ----
  property real pingMs: 0
  property real packetLoss: 0
  property real up: 0                          // B/s
  property real down: 0

  // ---- speedtest ----
  property bool speedtestBusy: false
  property var speedtest: null                 // see `wifi.sh --speedtest`
  property string speedtestError: ""
  property var activeSpeedtest: null

  // ---- lifecycle ----
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

  // ---- views ----
  function showList() {
    view = "list";
    selected = null;
    password = "";
    connectStatus = "";
    connectError = "";
    dnsError = "";
    stopSpeedtest();
  }

  // ---- Network settings ----
  property var saved: []                       // see wifi.sh --saved
  property var details: null                   // see wifi.sh --details
  property bool savedBusy: false
  property string saveError: ""
  property string hiddenError: ""
  property bool hiddenBusy: false
  readonly property bool connectionBusy: connectingSsid !== "" || hiddenBusy

  function refreshSaved() { if (radioOn) savedProc.running = true; }
  function refreshDetails() { if (connected) detailsProc.running = true; }

  function setSaved(uuid, key, value, extra) {
    if (savedBusy) return;
    savedBusy = true;
    saveError = "";
    run(setSavedProc, ["--set", uuid, key, value, extra ?? ""]);
  }

  // ---- Ethernet and the hotspot ----
  property var ethernet: null                  // see wifi.sh --ethernet
  property string ethernetError: ""
  property bool ethernetBusy: false
  property var hotspot: null                   // see wifi.sh --hotspot
  property string hotspotError: ""
  property bool hotspotBusy: false

  function refreshEthernet() { ethernetProc.running = true; }
  function refreshHotspot() { hotspotProc.running = true; }

  function setEthernet(on) {
    if (ethernetBusy) return;
    ethernetBusy = true;
    ethernetError = "";
    run(ethernetActionProc, ["--ethernet", on ? "on" : "off"]);
  }

  function setHotspot(on) {
    if (hotspotBusy) return;
    hotspotBusy = true;
    hotspotError = "";
    run(hotspotActionProc, ["--hotspot-switch", on ? "on" : "off"]);
  }

  // one hotspot setting; a password goes through $WIFI_PASS
  function setHotspotSetting(key, value) {
    if (hotspotBusy) return;
    hotspotBusy = true;
    hotspotError = "";
    hotspotActionProc.environment = { WIFI_PASS: key === "password" ? value : "" };
    run(hotspotActionProc, ["--hotspot-set", key, key === "password" ? "" : value]);
  }

  function disconnectNetwork() {
    if (!connected) return;
    run(disconnectProc, ["--disconnect"]);
  }

  function connectHidden(name, pw) {
    if (connectionBusy || name === "") return;
    hiddenBusy = true;
    hiddenError = "";
    hiddenProc.environment = { WIFI_PASS: pw };
    run(hiddenProc, ["--hidden", name]);
  }

  function measure() {
    if (!popupOpen || speedtestBusy) return;
    speedtest = null;
    speedtestError = "";
    speedtestBusy = true;
    speedtestTimeout.restart();
    const request = speedtestFactory.createObject(root);
    if (!request) {
      stopSpeedtest();
      speedtestError = "could not start speedtest";
      return;
    }
    activeSpeedtest = request;
    request.running = true;
  }

  // ---- actions ----
  function toggleRadio() {
    if (toggling) return;
    toggling = true;
    radioError = "";
    radioOn = !radioOn;
    if (!radioOn) {
      networks = [];
      showList();
    }
    run(radioProc, ["--radio", radioOn ? "on" : "off"]);
  }

  function connectTo(net) {
    if (!radioOn || connectionBusy || (connected && net.ssid === ssid)) return;
    if (net.secure && !net.saved) {
      selected = net;
      password = "";
      view = "password";
      return;
    }
    connect(net.ssid, "");
  }

  function submitPassword() {
    if (!connectionBusy && password !== "") connect(selected.ssid, password);
  }

  function setDns(servers) {
    if (!connected || dnsBusy) return;
    dnsBusy = true;
    dnsError = "";
    run(dnsSetProc, ["--dns", "set", servers]);
  }

  function scan() {
    if (!radioOn || scanProc.running) return;
    scanning = true;
    scanError = "";
    scanProc.running = true;
  }

  // ---- internals ----
  function run(proc, args) {
    proc.command = ["bash", root.script].concat(args);
    proc.running = true;
  }

  function parse(text) {
    return Reply.parse(text, "wifi.sh", null);
  }

  function refresh() {
    refreshStatus();
    refreshNetworks();
    refreshDns();
    refreshDetails();
    refreshEthernet();
    refreshHotspot();
  }

  function refreshStatus() { statusProc.running = true; }
  function refreshNetworks() { if (radioOn) networksProc.running = true; }
  function refreshDns() { if (connected) dnsGetProc.running = true; }

  function connect(name, pw) {
    if (!radioOn || connectionBusy || name === "") return;
    connectingSsid = name;
    connectStatus = "";
    connectError = "";
    connectProc.environment = { WIFI_PASS: pw };
    run(connectProc, ["--connect", name]);
  }

  function stopSpeedtest() {
    const request = activeSpeedtest;
    activeSpeedtest = null;
    speedtestBusy = false;
    if (request) request.running = false;
    speedtestTimeout.stop();
  }

  function finishSpeedtest(request, text) {
    if (activeSpeedtest !== request) {
      Qt.callLater(request.destroy);
      return;
    }
    activeSpeedtest = null;
    speedtestBusy = false;
    speedtestTimeout.stop();
    const o = parse(text);
    speedtest = o?.ok ? o : null;
    speedtestError = o?.ok ? "" : (o?.error ?? "speedtest failed");
    Qt.callLater(request.destroy);
  }

  // ---- events ----
  // NetworkManager reports each change (a link up or down, an access point seen):
  // the first one re-reads at once, the ones after it in changeMs come as one more.
  property bool changePending: false

  function changed() {
    if (changeTimer.running) { changePending = true; return; }
    refresh();
    changeTimer.restart();
  }

  Process {
    id: listenProc
    command: ["bash", root.script, "--listen"]
    running: true
    stdout: SplitParser { onRead: root.changed() }
    onExited: listenRestart.restart()
  }

  Timer {
    id: listenRestart
    interval: 3000
    onTriggered: listenProc.running = true
  }

  Timer {
    id: changeTimer
    interval: root.changeMs
    onTriggered: if (root.changePending) {
      root.changePending = false;
      root.refresh();
      changeTimer.restart();
    }
  }

  // ---- polling ----
  // the fallback when no event comes (signal level, a missed change)
  Timer {
    interval: root.popupOpen ? root.statusPollMs : root.idlePollMs
    running: true
    repeat: true
    onTriggered: root.refreshStatus()
  }

  // Signal levels come from NM's scan cache: re-read it while the popup is
  // open and rescan every fourth tick so the other access points update too.
  Timer {
    property int tick: 0

    interval: root.statusPollMs
    running: root.popupOpen && root.radioOn
    repeat: true
    onTriggered: ++tick % 4 === 0 ? root.scan() : root.refreshNetworks()
  }

  Timer {
    interval: root.pingPollMs
    running: root.popupOpen && root.connected
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!pingProc.running) pingProc.running = true
  }

  Timer {
    id: trafficRestart
    interval: root.trafficRestartMs
    onTriggered: if (root.popupOpen) trafficProc.running = true
  }

  // ---- transient results ----
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
    id: speedtestTimeout
    interval: root.speedtestTimeoutMs
    onTriggered: {
      root.stopSpeedtest();
      root.speedtestError = "timeout";
    }
  }

  // ---- processes ----
  Process {
    id: statusProc
    command: ["bash", root.script, "--status"]
    property bool started: false
    onStarted: started = true
    onRunningChanged: {
      if (running) return;
      if (started) { started = false; return; }
      root.statusError = "could not start Wi-Fi status query";
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        if (!o || (o.radio !== "on" && o.radio !== "off") ||
            typeof o.state !== "string" || typeof o.ssid !== "string" ||
            typeof o.ip !== "string" || typeof o.gateway !== "string") {
          root.statusError = o?.error ?? "bad Wi-Fi status reply";
          return;
        }
        if (!root.toggling) root.radioOn = o.radio === "on";
        root.linkState = o.state;
        root.ssid = o.ssid;
        root.ipAddress = o.ip;
        root.gateway = o.gateway;
        root.statusError = "";
      }
    }
  }

  Process {
    id: networksProc
    command: ["bash", root.script, "--list"]
    property bool started: false
    onStarted: started = true
    onRunningChanged: {
      if (running) return;
      if (started) { started = false; return; }
      root.networkError = "could not start Wi-Fi network query";
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const list = Reply.parseList(text, null);
        if (!Array.isArray(list) || !list.every(network => network &&
            typeof network.ssid === "string" && typeof network.signal === "number" &&
            typeof network.secure === "boolean" && typeof network.active === "boolean" &&
            typeof network.saved === "boolean")) {
          root.networkError = "bad Wi-Fi network list";
          return;
        }
        root.networks = list;
        root.networkError = "";
      }
    }
  }

  Process {
    id: scanProc
    command: ["bash", root.script, "--scan"]
    property bool started: false
    onStarted: started = true
    onRunningChanged: {
      if (running) return;
      if (started) { started = false; return; }
      root.scanning = false;
      root.scanError = "could not start Wi-Fi scan";
      root.refreshNetworks();
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.scanError = o?.ok ? "" : (o?.error ?? "could not scan for networks");
        root.refreshNetworks();
        root.scanning = false;
      }
    }
  }

  Process {
    id: radioProc
    property bool started: false
    onStarted: started = true
    onRunningChanged: {
      if (running) return;
      if (started) { started = false; return; }
      root.radioOn = !root.radioOn;
      root.toggling = false;
      root.radioError = "could not start Wi-Fi radio request";
      root.refreshStatus();
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        if (!o?.ok) {
          root.radioOn = !root.radioOn;
          root.toggling = false;
          root.radioError = o?.error ?? "could not switch Wi-Fi radio";
          root.refreshStatus();
          return;
        }
        radioSettle.restart();
      }
    }
  }

  Process {
    id: connectProc
    property bool started: false
    onStarted: started = true
    onRunningChanged: {
      if (running) return;
      if (started) { started = false; return; }
      connectProc.environment = {};
      root.connectingSsid = "";
      root.connectStatus = "error";
      root.connectError = "could not start connection request";
      connectClear.restart();
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        connectProc.environment = {};
        root.connectingSsid = "";
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
    command: ["bash", root.script, "--dns", "get"]
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
    property bool started: false
    onStarted: started = true
    onRunningChanged: {
      if (running) return;
      if (started) { started = false; return; }
      root.dnsBusy = false;
      root.dnsError = "could not start DNS update";
      root.refreshDns();
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.dnsBusy = false;
        root.dnsError = o?.ok ? "" : (o?.error ?? "could not set DNS");
        root.refreshDns();
      }
    }
  }

  Process {
    id: pingProc
    command: ["bash", root.script, "--ping"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.pingMs = o?.ok ? o.ping : 0;
        root.packetLoss = o?.ok ? o.loss : 0;
      }
    }
  }

  Process {
    id: savedProc
    command: ["bash", root.script, "--saved"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        if (o?.ok) root.saved = o.saved;
      }
    }
  }

  Process {
    id: detailsProc
    command: ["bash", root.script, "--details"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.details = o?.ok ? o : null;
      }
    }
  }

  Process {
    id: setSavedProc
    property bool started: false
    onStarted: started = true
    onRunningChanged: {
      if (running) return;
      if (started) { started = false; return; }
      root.savedBusy = false;
      root.saveError = "could not start network update";
      root.refreshSaved();
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.savedBusy = false;
        root.saveError = o?.ok ? "" : (o?.error ?? "could not change the network");
        root.refreshSaved();
      }
    }
  }

  Process {
    id: disconnectProc
    stdout: StdioCollector {
      onStreamFinished: root.refresh()
    }
  }

  Process {
    id: hiddenProc
    property bool started: false
    onStarted: started = true
    onRunningChanged: {
      if (running) return;
      if (started) { started = false; return; }
      hiddenProc.environment = {};
      root.hiddenBusy = false;
      root.hiddenError = "could not start connection request";
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        hiddenProc.environment = {};
        root.hiddenBusy = false;
        root.hiddenError = o?.ok ? "" : (o?.error ?? "could not connect");
        root.refresh();
        root.refreshSaved();
      }
    }
  }

  Process {
    id: ethernetProc
    command: ["bash", root.script, "--ethernet"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.ethernet = o?.ok ? o : null;
      }
    }
  }

  Process {
    id: ethernetActionProc
    property bool started: false
    onStarted: started = true
    onRunningChanged: {
      if (running) return;
      if (started) { started = false; return; }
      root.ethernetBusy = false;
      root.ethernetError = "could not start wired connection change";
      root.refreshEthernet();
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.ethernetBusy = false;
        root.ethernetError = o?.ok ? "" : (o?.error ?? "could not change the wired connection");
        root.refreshEthernet();
      }
    }
  }

  Process {
    id: hotspotProc
    command: ["bash", root.script, "--hotspot"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.hotspot = o?.ok ? o : null;
      }
    }
  }

  Process {
    id: hotspotActionProc
    property bool started: false
    onStarted: started = true
    onRunningChanged: {
      if (running) return;
      if (started) { started = false; return; }
      hotspotActionProc.environment = {};
      root.hotspotBusy = false;
      root.hotspotError = "could not start hotspot change";
      root.refreshHotspot();
    }
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        hotspotActionProc.environment = {};
        root.hotspotBusy = false;
        root.hotspotError = o?.ok ? "" : (o?.error ?? "could not change the hotspot");
        root.refreshHotspot();
      }
    }
  }

  Component {
    id: speedtestFactory
    Process {
      id: request
      command: ["bash", root.script, "--speedtest"]
      property bool started: false
      onStarted: started = true
      onRunningChanged: {
        if (running) return;
        if (started) { started = false; return; }
        root.finishSpeedtest(request,
          JSON.stringify({ok: false, error: "could not start speedtest"}));
      }
      stdout: StdioCollector {
        onStreamFinished: root.finishSpeedtest(request, text)
      }
    }
  }

  Process {
    id: trafficProc
    command: ["bash", root.script, "--traffic"]
    stdout: SplitParser {
      onRead: line => {
        const o = root.parse(line);
        if (!o) return;
        root.up = o.up;
        root.down = o.down;
      }
    }
    onExited: if (root.popupOpen) trafficRestart.restart()
  }

  FileView {
    path: Quickshell.shellDir + "/modules/wifi/dns_providers.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.dnsProviders = Reply.parseList(text())
  }
}
