pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Battery state, charge limit, power profile and GPU mode on top of
// scripts/battery.sh. The bar module and the popup only read these properties
// and call these functions. The charge limit resets on reboot, so the chosen
// one persists in the shell's state dir and is re-applied on start.
Singleton {
  id: root

  // ---- battery ----
  property var info: ({})                      // see `battery.sh --status`

  readonly property bool present: info.present ?? false
  readonly property int capacity: info.capacity ?? 0
  readonly property bool plugged: info.plugged ?? false
  readonly property bool charging: info.status === "Charging"
  readonly property bool discharging: info.status === "Discharging"
  readonly property real power: info.power ?? 0                // W
  readonly property real energy: info.energy ?? 0              // Wh
  readonly property real energyFull: info.energyFull ?? 0      // Wh
  readonly property real energyDesign: info.energyDesign ?? 0  // Wh
  readonly property int cycles: info.cycles ?? 0
  readonly property int threshold: info.threshold ?? 100
  readonly property int health: energyDesign > 0 ? Math.round(energyFull / energyDesign * 100) : 0

  // Minutes until empty (discharging) or until the charge limit (charging); -1 when unknown.
  readonly property int minutesLeft: {
    if (power <= 0) return -1;
    if (discharging) return Math.round(energy / power * 60);
    if (charging) return Math.max(0, Math.round((energyFull * threshold / 100 - energy) / power * 60));
    return -1;
  }

  // ---- power profile / GPU ----
  readonly property string profile: info.profile ?? ""
  readonly property var profiles: info.profiles ?? []
  readonly property bool saver: profile === Theme.powerSaverProfile
  // Material battery_android by charge: empty under 10, then 2, 4, 5 and 6 bars, full at 100
  readonly property string levelIcon: capacity >= 100 ? "battery-full"
    : capacity >= 70 ? "battery-6" : capacity >= 50 ? "battery-5"
    : capacity >= 30 ? "battery-4" : capacity >= 10 ? "battery-2" : "battery-0"

  property string gpuMode: ""
  property string gpuPending: ""
  property string gpuAction: ""                // supergfxctl's required user action

  // ---- actions ----
  property var busy: null                      // value being applied, for its spinner
  property string error: ""

  function popupShown() {
    error = "";
    refresh();
    run(gpuProc, ["--gpu"]);
  }

  function setThreshold(percent) {
    state.threshold = percent;
    apply(["--threshold", String(percent)], percent);
  }

  function setProfile(name) { apply(["--profile", name], name); }

  // Power saver is the quiet profile; turning it off restores the one before.
  function setSaver(on) {
    if (on) {
      state.lastProfile = profile;
      setProfile(Theme.powerSaverProfile);
    } else {
      setProfile(state.lastProfile !== Theme.powerSaverProfile ? state.lastProfile : "balanced");
    }
  }
  function setGpuMode(mode) { apply(["--gpu-mode", mode], mode); }

  // ---- internals ----
  property var notified: []                    // notify levels already shown this discharge

  function run(proc, args) {
    proc.command = ["bash", Theme.batteryScript].concat(args);
    proc.running = true;
  }

  function apply(args, value) {
    if (actionProc.running) return;
    busy = value;
    error = "";
    run(actionProc, args);
  }

  function refresh() {
    if (!statusProc.running) run(statusProc, ["--status"]);
  }

  function checkLevel() {
    if (!discharging) {
      notified = [];
      return;
    }
    for (const level of Theme.batteryNotifyLevels) {
      if (capacity > level || notified.includes(level)) continue;
      notified = notified.concat(level);
      Quickshell.execDetached(["notify-send", "-u", level <= 5 ? "critical" : "normal",
                               "Battery low", capacity + "% remaining"]);
      break;
    }
  }

  onCapacityChanged: checkLevel()
  onDischargingChanged: checkLevel()

  // ---- polling ----
  Timer {
    interval: Theme.batteryIntervalMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // ---- processes ----
  Process {
    id: statusProc
    stdout: StdioCollector {
      onStreamFinished: {
        try { root.info = JSON.parse(text); } catch (e) {}
      }
    }
  }

  Process {
    id: gpuProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          const o = JSON.parse(text);
          root.gpuMode = o.mode;
          root.gpuPending = o.pending;
          root.gpuAction = o.action;
        } catch (e) {}
      }
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector {
      onStreamFinished: {
        let o = null;
        try { o = JSON.parse(text); } catch (e) {}
        root.busy = null;
        if (!o?.ok) root.error = o?.error ?? "action failed";
        root.refresh();
        root.run(gpuProc, ["--gpu"]);
      }
    }
  }

  // ---- files ----
  FileView {
    id: stateFile
    path: Quickshell.statePath("battery.json")
    printErrors: false
    onAdapterUpdated: writeAdapter()
    onLoaded: if (state.threshold < 100) root.run(actionProc, ["--threshold", String(state.threshold)])
    onLoadFailed: writeAdapter()

    JsonAdapter {
      id: state
      property int threshold: 100
      property string lastProfile: "balanced"
    }
  }
}
