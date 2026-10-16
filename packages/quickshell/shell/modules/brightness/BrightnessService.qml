pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// Backlight, night light and dimming on top of scripts/brightness.sh. The bar
// module and the popup only read these properties and call these functions.
// Night light, temperature and dimming persist in the shell's state dir;
// presets and the schedule live in night_light.json. An enabled schedule
// switches night light at its start and end; the switch overrides it in between.
Singleton {
  id: root

  // ---- backlight ----
  property int brightness: 0                   // %

  // ---- night light ----
  readonly property bool nightActive: state.night
  readonly property int temperature: state.temperature
  readonly property int gamma: state.gamma     // %, below 100 dims past the backlight minimum
  readonly property var presets: config.presets
  readonly property var schedule: config.schedule

  property var inSchedule: null                // null until the first check

  // ---- actions ----
  function setNight(on) { state.night = on; }

  function setTemperature(kelvin) {
    state.temperature = Math.round(Math.max(Theme.nightTemperatureMin, Math.min(Theme.nightTemperatureMax, kelvin)));
  }

  function setGamma(percent) {
    state.gamma = Math.round(Math.max(Theme.dimGammaMin, Math.min(100, percent)));
  }

  function setBrightness(percent) {
    brightness = Math.round(Math.max(1, Math.min(100, percent)));
    pendingSet = brightness;
    flushBacklight();
  }

  function stepBrightness(percent) {
    pendingStep += percent;
    flushBacklight();
  }

  // ---- internals ----
  property bool ready: false                   // state file read; safe to apply
  property int pendingSet: -1
  property int pendingStep: 0
  property bool pendingApply: false

  function run(proc, args) {
    proc.command = ["bash", Theme.brightnessScript].concat(args);
    proc.running = true;
  }

  // One backlight process at a time: a slider drag keeps only the latest
  // value, wheel steps are summed.
  function flushBacklight() {
    if (backlightProc.running) return;
    if (pendingSet >= 0) {
      run(backlightProc, ["--set", String(pendingSet)]);
      pendingSet = -1;
    } else if (pendingStep !== 0) {
      run(backlightProc, ["--step", (pendingStep > 0 ? "+" : "") + pendingStep]);
      pendingStep = 0;
    }
  }

  function apply() {
    if (!ready) return;
    if (applyProc.running) {
      pendingApply = true;
      return;
    }
    run(applyProc, ["--apply", nightActive ? String(temperature) : "off", String(gamma)]);
  }

  function minutes(time) {
    const [h, m] = time.split(":").map(Number);
    return h * 60 + m;
  }

  // Switch only when the window is entered or left, so a manual toggle holds
  // until the next boundary.
  function checkSchedule() {
    if (!ready || !schedule?.enabled) return;
    const now = new Date();
    const t = now.getHours() * 60 + now.getMinutes();
    const start = minutes(schedule.start);
    const end = minutes(schedule.end);
    const inside = start <= end ? t >= start && t < end : t >= start || t < end;
    if (inside !== inSchedule) setNight(inside);
    inSchedule = inside;
  }

  onNightActiveChanged: applyDelay.restart()
  onTemperatureChanged: applyDelay.restart()
  onGammaChanged: applyDelay.restart()
  onScheduleChanged: checkSchedule()

  // ---- timers ----
  Timer {
    interval: Theme.brightnessIntervalMs
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!backlightProc.running) root.run(backlightProc, ["--get"])
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.checkSchedule()
  }

  // Coalesces slider drags into one hyprsunset call per frame or so.
  Timer {
    id: applyDelay
    interval: 50
    onTriggered: root.apply()
  }

  Timer {
    id: saveDelay
    interval: 500
    onTriggered: stateFile.writeAdapter()
  }

  // ---- processes ----
  Process {
    id: backlightProc
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          // A drag still queued wins over the value this run read back.
          if (root.pendingSet < 0) root.brightness = JSON.parse(text).brightness;
        } catch (e) {}
      }
    }
    onExited: root.flushBacklight()
  }

  Process {
    id: applyProc
    onExited: {
      if (!root.pendingApply) return;
      root.pendingApply = false;
      root.apply();
    }
  }

  // ---- files ----
  FileView {
    id: stateFile
    path: Quickshell.statePath("brightness.json")
    onAdapterUpdated: saveDelay.restart()
    onLoaded: {
      root.ready = true;
      root.checkSchedule();
      root.apply();
    }
    printErrors: false
    onLoadFailed: {
      root.ready = true;
      writeAdapter();
      root.checkSchedule();
      root.apply();
    }

    JsonAdapter {
      id: state
      property bool night: false
      property int temperature: 4000
      property int gamma: 100
    }
  }

  FileView {
    path: Quickshell.shellDir + "/modules/brightness/night_light.json"
    watchChanges: true
    onFileChanged: reload()

    JsonAdapter {
      id: config
      property var presets: []
      property var schedule: ({ enabled: false, start: "21:00", end: "07:00" })
    }
  }
}
