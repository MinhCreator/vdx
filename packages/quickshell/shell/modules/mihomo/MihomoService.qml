pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../../kit/reply.js" as Reply

// mihomo state and actions on top of scripts/mihomo.sh. The bar module and the
// popup only read these properties and call these functions.
Singleton {
  id: root

  // ---- service ----
  property bool serviceOn: false
  property bool toggling: false                // start / stop in flight
  property string mode: "rule"
  property string group: Theme.mihomoGroup
  property string current: ""                  // node the policy group points at
  property string currentProvider: ""          // provider of that node
  property int currentDelay: 0                 // last measured ping of `current`, ms

  // ---- providers / servers ----
  property var providers: []                   // [{name, nodes}]
  property string provider: ""                 // provider whose servers are listed
  property var nodes: []                       // [{name, alive, delay}]

  // ---- actions ----
  property bool updating: false
  property bool pinging: false
  property string error: ""                    // last failed action, shown in the popup

  // ---- traffic (measured only while the popup is open) ----
  property real up: 0
  property real down: 0
  property real upTotal: 0
  property real downTotal: 0

  property bool popupOpen: false

  // ---- lifecycle ----
  function popupShown() {
    popupOpen = true;
    error = "";
    refresh();
  }

  function popupHidden() {
    popupOpen = false;
  }

  onPopupOpenChanged: trafficProc.running = popupOpen
  onProviderChanged: refreshNodes()

  Component.onCompleted: refresh()

  // ---- actions ----
  function toggleService() {
    if (toggling) return;
    toggling = true;
    serviceOn = !serviceOn;
    run(toggleProc, ["--toggle"]);
  }

  function selectNode(name) {
    if (serviceOn) run(selectProc, ["--select", name]);
  }

  function pingNodes() {
    if (!serviceOn || provider === "" || pinging) return;
    pinging = true;
    error = "";
    run(pingProc, ["--ping", provider]);
  }

  function runUpdate() {
    if (updating) return;
    updating = true;
    error = "";
    run(updateProc, ["--update"]);
  }

  function openMihomoConfig() { run(pathProc, ["--config-path"]); }
  function openProviderConfig(name) { run(pathProc, ["--path", name]); }

  // ---- internals ----
  function run(proc, args) {
    proc.command = ["bash", Theme.mihomoScript].concat(args);
    proc.running = true;
  }

  function parse(text) {
    return Reply.parse(text, "mihomo.sh", null);
  }

  function refresh() {
    refreshStatus();
    refreshProviders();
  }

  function refreshStatus() { statusProc.running = true; }
  function refreshProviders() { providersProc.running = true; }

  function refreshNodes() {
    if (serviceOn && provider !== "") run(nodesProc, ["--nodes", provider]);
    else nodes = [];
  }

  // ---- polling ----
  Timer {
    interval: Theme.mihomoStatusIntervalMs
    running: true
    repeat: true
    onTriggered: root.refreshStatus()
  }

  Timer {
    id: trafficRestart
    interval: Theme.mihomoTrafficRestartMs
    onTriggered: if (root.popupOpen) trafficProc.running = true
  }

  // ---- after a toggle ----
  Timer {
    id: toggleSettle
    interval: 1500                             // TUN + controller need a moment
    onTriggered: {
      root.toggling = false;
      root.refresh();
    }
  }

  // ---- processes ----
  Process {
    id: statusProc
    command: ["bash", Theme.mihomoScript, "--status"]
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        if (!o) return;
        const wasOn = root.serviceOn;
        if (!root.toggling) root.serviceOn = o.service === "on";
        root.mode = o.mode || "rule";
        root.group = o.group || Theme.mihomoGroup;
        root.current = o.node || "";
        root.currentProvider = o.provider || "";
        root.currentDelay = o.delay || 0;
        if (root.serviceOn && !wasOn) root.refreshProviders();
      }
    }
  }

  Process {
    id: providersProc
    command: ["bash", Theme.mihomoScript, "--providers"]
    stdout: StdioCollector {
      onStreamFinished: {
        const list = root.parse(text);
        if (!Array.isArray(list)) return;
        const has = name => list.some(p => p.name === name);
        root.providers = list;
        if (!has(root.provider))
          root.provider = has(root.currentProvider) ? root.currentProvider : (list[0]?.name ?? "");
        root.refreshNodes();
      }
    }
  }

  Process {
    id: nodesProc
    stdout: StdioCollector {
      onStreamFinished: {
        const list = root.parse(text);
        root.nodes = Array.isArray(list) ? list : [];
      }
    }
  }

  Process {
    id: selectProc
    stdout: StdioCollector {
      onStreamFinished: root.refreshStatus()
    }
  }

  Process {
    id: pingProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.pinging = false;
        if (!o?.ok) root.error = o?.error ?? "ping failed";
        root.refreshNodes();
        root.refreshStatus();
      }
    }
  }

  Process {
    id: updateProc
    stdout: StdioCollector {
      onStreamFinished: {
        const o = root.parse(text);
        root.updating = false;
        if (!o?.ok) root.error = o?.error ?? "update failed";
        root.refresh();
      }
    }
  }

  Process {
    id: toggleProc
    stdout: StdioCollector {
      onStreamFinished: toggleSettle.restart()
    }
  }

  Process {
    id: pathProc
    stdout: StdioCollector {
      onStreamFinished: {
        const path = text.trim();
        if (path !== "") Quickshell.execDetached(["kitty", "-e", "nvim", path]);
      }
    }
  }

  Process {
    id: trafficProc
    command: ["bash", Theme.mihomoScript, "--traffic"]
    stdout: SplitParser {
      onRead: line => {
        const o = root.parse(line);
        if (!o) return;
        root.up = o.up ?? root.up;
        root.down = o.down ?? root.down;
        root.upTotal = o.upTotal ?? root.upTotal;
        root.downTotal = o.downTotal ?? root.downTotal;
      }
    }
    onExited: if (root.popupOpen) trafficRestart.restart()
  }
}
