"""Run device state/action logic against local objects, without hardware access."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from tests.check_shell_ui import qml_block, qml_function
from tests.qml_runtime import SHELL, run_quickshell


def handler(source, process):
    return qml_block(source[source.index("id: " + process):], "onStreamFinished:").split(":", 1)[1]


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class DeviceServices(unittest.TestCase):
    def evaluate(self, definitions, action):
        with tempfile.TemporaryDirectory(prefix="shell-devices-") as tmp:
            root = Path(tmp)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
Scope {
  id: root
''' + definitions + '''
  Timer { interval: 10; running: true; onTriggered: {
    const result = (function() { ''' + action + ''' })();
    console.warn("DEVICE_RESULT:" + JSON.stringify(result)); Qt.quit();
  } }
}
''')
            try:
                output = run_quickshell(root)
            except subprocess.TimeoutExpired as error:
                self.fail(f"Quickshell fixture timed out: {error.stdout}\n{error.stderr}")
            results = [line.split("DEVICE_RESULT:", 1)[1]
                       for line in output.splitlines() if "DEVICE_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            return json.loads(results[0])

    def battery(self, action):
        source = (SHELL / "modules/battery/BatteryService.qml").read_text()
        definitions = '''
  property var busy: null
  property string actionError: ""
  property string profile: "performance"
  readonly property string saverProfile: "quiet"
  property var calls: []
  QtObject { id: actionProc; property bool running: false }
  QtObject { id: state; property int threshold: 100; property string lastProfile: "balanced" }
  function run(proc, args) { calls = calls.concat([args]); }
'''
        definitions += "\n".join(qml_function(source, name)
                                 for name in ("apply", "setThreshold", "setProfile", "setSaver"))
        return self.evaluate(definitions, action)

    def bluetooth_adapter(self, action):
        source = (SHELL / "modules/bluetooth/BluetoothService.qml").read_text()
        definitions = '''
  property bool adapterBusy: false
  property var adapterQueue: []
  property string busyMac: ""
  property string actionError: ""
  property var calls: []
  property string text: ""
  QtObject { id: adapterProc; property bool running: false }
  function run(proc, args) { calls = calls.concat([args]); }
  function parse(text) { return JSON.parse(text); }
  function refresh() {}
'''
        definitions += "\n".join(qml_function(source, name)
                                 for name in ("setAdapter", "flushAdapter"))
        definitions += "\nfunction complete(text) " + handler(source, "adapterProc")
        return self.evaluate(definitions, action)

    def test_bluetooth_adapter_actions_run_in_fifo_order(self):
        result = self.bluetooth_adapter('''
          setAdapter(["--alias", "one"]); setAdapter(["--pairable", "on"]);
          const first = calls.slice();
          complete(JSON.stringify({ok: true})); const second = calls.slice();
          complete(JSON.stringify({ok: true}));
          return {first, second, calls, queue: adapterQueue, busy: adapterBusy};
        ''')
        expected_calls = [["--alias", "one"], ["--pairable", "on"]]
        self.assertEqual(result, {"first": expected_calls[:1], "second": expected_calls,
                                  "calls": expected_calls, "queue": [], "busy": False})

    def test_bluetooth_status_rejects_malformed_device_list(self):
        source = (SHELL / "modules/bluetooth/BluetoothService.qml").read_text()
        callback = handler(source, "statusProc").replace(
            'Reply.parse(text, "bluetooth.sh", null)', "JSON.parse(text)")
        result = self.evaluate('''
  property string error: ""
  property bool powered: true
  property bool discovering: true
  property var adapter: ({alias: "old"})
  property var devices: [{mac: "old-device"}]
  property bool toggling: false
  property string text: ""
  function parse(text) { return JSON.parse(text); }
  function complete(text) ''' + callback, '''
          complete(JSON.stringify({ok: true}));
          return {error, powered, discovering, adapter, devices};
        ''')
        self.assertEqual(result, {
            "error": "bad bluetooth status reply", "powered": True, "discovering": True,
            "adapter": {"alias": "old"}, "devices": [{"mac": "old-device"}],
        })

    def test_bluetooth_device_and_adapter_commands_are_serialized(self):
        source = (SHELL / "modules/bluetooth/BluetoothService.qml").read_text()
        definitions = '''
  property bool powered: true
  property string busyMac: ""
  property bool adapterBusy: false
  property var adapterQueue: []
  property string actionError: ""
  property string text: ""
  property var calls: []
  QtObject { id: adapterProc; property bool running: false }
  QtObject { id: deviceProc; property bool running: false }
  function run(proc, args) { calls = calls.concat([args]); }
  function parse(text) { return JSON.parse(text); }
  function refresh() {}
'''
        definitions += "\n".join(qml_function(source, name)
                                  for name in ("toggleDevice", "setAdapter", "flushAdapter"))
        definitions += "\nfunction completeDevice(text) " + handler(source, "deviceProc")
        definitions += "\nfunction completeAdapter(text) " + handler(source, "adapterProc")
        result = self.evaluate(definitions, '''
          toggleDevice({mac: "A", connected: false});
          setAdapter(["--block", "A", "on"]);
          toggleDevice({mac: "B", connected: false});
          const whileDeviceRuns = calls.slice();
          completeDevice(JSON.stringify({ok: true}));
          const whileAdapterRuns = calls.slice();
          toggleDevice({mac: "B", connected: false});
          const whileAdapterBusy = calls.slice();
          completeAdapter(JSON.stringify({ok: true}));
          return {whileDeviceRuns, whileAdapterRuns, whileAdapterBusy, calls,
                  queued: adapterQueue.length, device: busyMac, adapterBusy};
        ''')
        expected = [["--connect", "A"], ["--block", "A", "on"]]
        self.assertEqual(result, {"whileDeviceRuns": expected[:1], "whileAdapterRuns": expected,
                                  "whileAdapterBusy": expected, "calls": expected, "queued": 0,
                                  "device": "", "adapterBusy": False})

    def test_wifi_saved_settings_reject_overlap_and_allow_retry_after_reply(self):
        source = (SHELL / "modules/wifi/WifiService.qml").read_text()
        result = self.evaluate('''
  property bool savedBusy: false
  property string saveError: ""
  property string text: ""
  property var calls: []
  QtObject { id: setSavedProc; property var command: []; property bool running: false }
  function run(proc, args) { calls = calls.concat([args]); }
  function parse(text) { return JSON.parse(text); }
  function refreshSaved() {}
''' + qml_function(source, "setSaved") + '''
  function complete(text) ''' + handler(source, "setSavedProc"), '''
          setSaved("fixture", "priority", "10"); setSaved("fixture", "metered", "yes");
          const first = calls.length;
          complete(JSON.stringify({ok: false, error: "write failed"}));
          const failed = saveError;
          setSaved("fixture", "metered", "no");
          return {first, retry: calls.length, error: failed, busy: savedBusy};
        ''')
        self.assertEqual(result, {"first": 1, "retry": 2, "error": "write failed", "busy": True})

    def test_wifi_scan_shows_busy_and_error_then_allows_retry(self):
        source = (SHELL / "modules/wifi/WifiService.qml").read_text()
        result = self.evaluate('''
  property bool radioOn: true
  property bool scanning: false
  property string scanError: ""
  property string text: ""
  property int calls: 0
  function parse(text) { return JSON.parse(text); }
  function refreshNetworks() {}
  QtObject { id: scanProc; property bool running: false; onRunningChanged: if (running) root.calls++ }
''' + qml_function(source, "scan") + '''
  function complete(text) { scanProc.running = false; ''' + handler(source, "scanProc") + ''' }
''', '''
          scan(); scan(); const callsDuringScan = calls; const busyDuringScan = scanning;
          complete(JSON.stringify({ok: false, error: "no network device"}));
          const errorAfterFailure = scanError;
          scan(); complete(JSON.stringify({ok: true}));
          return {callsDuringScan, busyDuringScan, errorAfterFailure, scanError, scanning};
        ''')
        self.assertEqual(result, {"callsDuringScan": 1, "busyDuringScan": True,
                                  "errorAfterFailure": "no network device", "scanError": "",
                                  "scanning": False})

    def test_bluetooth_adapter_failure_discards_dependent_queued_actions(self):
        result = self.bluetooth_adapter('''
          setAdapter(["--alias", "one"]); setAdapter(["--pairable", "on"]);
          complete(JSON.stringify({ok: false, error: "adapter unavailable"}));
          return {calls, queue: adapterQueue, busy: adapterBusy, error: actionError};
        ''')
        self.assertEqual(result, {"calls": [["--alias", "one"]], "queue": [],
                                  "busy": False, "error": "adapter unavailable"})

    def test_battery_rejects_overlap_before_process_start_without_saving_rejected_limit(self):
        result = self.battery('''
          setProfile("performance"); setThreshold(60);
          return {calls: calls, threshold: state.threshold, busy: busy};
        ''')
        self.assertEqual(result, {"calls": [["--profile", "performance"]], "threshold": 100,
                                  "busy": "performance"})

    def test_battery_repeated_saver_request_preserves_previous_profile(self):
        result = self.battery('''
          setSaver(true); profile = "quiet"; setSaver(true);
          return {calls: calls, previous: state.lastProfile};
        ''')
        self.assertEqual(result, {"calls": [["--profile", "quiet"]], "previous": "performance"})

    def test_battery_saver_restores_the_profile_active_before_saver(self):
        result = self.battery('''
          setSaver(true); const previous = state.lastProfile;
          busy = null; profile = "quiet"; setSaver(false);
          return {calls, previous, busy};
        ''')
        self.assertEqual(result, {"calls": [["--profile", "quiet"], ["--profile", "performance"]],
                                  "previous": "performance", "busy": "performance"})

    def test_battery_backend_failure_is_visible_and_allows_retry(self):
        source = (SHELL / "modules/battery/BatteryService.qml").read_text()
        callback = handler(source, "actionProc").replace(
            'Reply.parse(text, "battery.sh")', "JSON.parse(text)")
        result = self.evaluate('''
  property var busy: "quiet"
  property string actionError: ""
  property string text: ""
  property var calls: []
  QtObject { id: actionProc; property bool running: false }
  QtObject { id: gpuProc }
  function parse(text) { return JSON.parse(text); }
  function refresh() {}
  function run(proc, args) { calls = calls.concat([args]); }
''' + qml_function(source, "apply") + qml_function(source, "setProfile") +
        "\nfunction complete(text) " + callback, '''
          complete(JSON.stringify({ok: false, error: "permission denied"}));
          const failed = {busy, error: actionError};
          calls = [];
          setProfile("balanced");
          return {failed, retry: calls, busy, error: actionError};
        ''')
        self.assertEqual(result, {
            "failed": {"busy": None, "error": "permission denied"},
            "retry": [["--profile", "balanced"]], "busy": "balanced", "error": "",
        })

    def test_battery_accepts_limit_after_previous_action_finishes(self):
        self.assertEqual(self.battery('''
          setProfile("quiet"); busy = null; setThreshold(80);
          return {count: calls.length, threshold: state.threshold, busy: busy};
        '''), {"count": 2, "threshold": 80, "busy": 80})

    def test_battery_capacity_label_distinguishes_missing_hardware(self):
        source = (SHELL / "modules/battery/BatteryService.qml").read_text()
        label = next(line for line in source.splitlines() if "property string capacityLabel:" in line)
        self.assertEqual(self.evaluate('''
  property bool present: false
  property int capacity: 0
''' + label, '''
          const absent = capacityLabel; present = true; capacity = 42;
          return [absent, capacityLabel];
        '''), ["—", "42%"])

    def test_battery_details_show_unknown_when_hardware_omits_them(self):
        source = (SHELL / "modules/battery/BatteryService.qml").read_text()
        source_lines = source.splitlines()
        names = ("cycles", "cyclesLabel", "health", "healthLabel", "energyLabel")
        properties = []
        for index, line in enumerate(source_lines):
            if any(" " + name + ":" in line for name in names):
                properties.append(line)
                if " energyLabel:" in line:
                    properties.append(source_lines[index + 1])
        result = self.evaluate('''
  property var info: ({cycles: null})
  property real energy: 0
  property real energyFull: 0
  property real energyDesign: 0
''' + "\n".join(properties), '''
          const unknown = [cyclesLabel, healthLabel, energyLabel];
          info = {cycles: 0}; energy = 12; energyFull = 45; energyDesign = 50;
          return {unknown, known: [cyclesLabel, healthLabel, energyLabel]};
        ''')
        self.assertEqual(result, {
            "unknown": ["—", "—", "—"],
            "known": ["0", "90%", "12.0 / 50.0 Wh"],
        })

    def test_battery_waits_for_a_valid_status_shape(self):
        source = (SHELL / "modules/battery/BatteryService.qml").read_text()
        callback = handler(source, "statusProc").replace(
            'Reply.parse(text, "battery.sh", null)', "JSON.parse(text)")
        result = self.evaluate('''
  property var info: ({})
  property bool ready: false
  property string statusError: ""
  property string text: ""
  function parse(text) { return JSON.parse(text); }
  function complete(text) ''' + callback, '''
          complete(JSON.stringify({ok: false, error: "backend missing"}));
          const afterError = {ready, statusError};
          complete(JSON.stringify({present: false}));
          return {afterError, ready, statusError, info};
        ''')
        self.assertEqual(result, {"afterError": {"ready": True, "statusError": "backend missing"},
                                  "ready": True, "statusError": "", "info": {"present": False}})

    def test_audio_missing_devices_are_not_live(self):
        source = (SHELL / "modules/audio/AudioService.qml").read_text()
        live = next(line for line in source.splitlines() if "readonly property bool live:" in line)
        result = self.evaluate('''
  property var sink: null
  property var source: null
  readonly property bool muted: sink?.audio?.muted ?? false
''' + live, '''
          const none = live;
          sink = {audio: {muted: true}}; const mutedSink = live;
          source = {audio: {muted: false}}; const microphone = live;
          source = null; sink = {audio: {muted: false}};
          return [none, mutedSink, microphone, live];
        ''')
        self.assertEqual(result, [False, False, True, True])

    def test_display_refresh_preserves_action_error_until_next_apply(self):
        source = (SHELL / "apps/display/DisplayService.qml").read_text()
        error_property = next(line for line in source.splitlines() if "property string error:" in line)
        result = self.evaluate(error_property + '''
  property string script: "unused"
  property string listError: ""
  property string actionError: ""
  property bool busy: true
  property string working: "text"
  property var pending: 1.2
  property var monitors: []
  property real textFactor: 1
  property var textScales: []
  property string text: ""
  property int appliedCount: 0
  function applied() { appliedCount++; }
  function refresh() {}
  function parse(text) { return JSON.parse(text); }
  QtObject { id: actProc; property var command: []; property bool running: false }
  function finishAction() ''' + handler(source, "actProc") + '''
  function finishList() ''' + handler(source, "listProc") + "\n" + qml_function(source, "run"), '''
          text = JSON.stringify({ok: false, error: "apply failed"}); finishAction();
          text = JSON.stringify({ok: true, monitors: [], text: 1, textScales: []}); finishList();
          const retained = error;
          run(["text", "1"], "text", 1);
          return {retained: retained, cleared: error, applied: appliedCount, busy: busy};
        ''')
        self.assertEqual(result, {"retained": "apply failed", "cleared": "", "applied": 0, "busy": True})

    def test_display_rejects_malformed_status_and_action_replies(self):
        source = (SHELL / "apps/display/DisplayService.qml").read_text()
        result = self.evaluate('''
  property string listError: ""
  property string actionError: ""
  property bool busy: true
  property string working: "text"
  property var pending: 1.2
  property var monitors: [{name: "old-monitor"}]
  property real textFactor: 1
  property var textScales: [1]
  property string text: ""
  property int appliedCount: 0
  function applied() { appliedCount++; }
  function refresh() {}
  function parse(text) { return JSON.parse(text); }
  function completeList(text) ''' + handler(source, "listProc") + '''
  function completeAction(text) ''' + handler(source, "actProc"), '''
          completeList(JSON.stringify({ok: true}));
          const list = {error: listError, monitors: monitors};
          completeAction(JSON.stringify({}));
          return {list, actionError, busy, working, pending, appliedCount};
        ''')
        self.assertEqual(result, {
            "list": {"error": "bad display status reply", "monitors": [{"name": "old-monitor"}]},
            "actionError": "display action failed", "busy": False, "working": "",
            "pending": None, "appliedCount": 0,
        })

    def test_bluetooth_scan_reports_failure_and_clears_error_on_success(self):
        source = (SHELL / "modules/bluetooth/BluetoothService.qml").read_text()
        result = self.evaluate('''
  property bool scanning: true
  property string actionError: ""
  property string text: ""
  function refresh() {}
  function parse(text) { return JSON.parse(text); }
  function complete() ''' + handler(source, "scanProc"), '''
          text = JSON.stringify({ok: false, error: "scan failed"}); complete();
          const failure = actionError;
          scanning = true; text = JSON.stringify({ok: true}); complete();
          return {failure: failure, error: actionError, busy: scanning};
        ''')
        self.assertEqual(result, {"failure": "scan failed", "error": "", "busy": False})

    def test_wifi_connection_paths_cannot_overlap(self):
        source = (SHELL / "modules/wifi/WifiService.qml").read_text()
        result = self.evaluate('''
  property bool radioOn: true
  property bool connected: false
  property string ssid: ""
  property string connectingSsid: ""
  property bool hiddenBusy: false
  property string hiddenError: ""
  readonly property bool connectionBusy: connectingSsid !== "" || hiddenBusy
  property string password: "secret"
  property string connectStatus: ""
  property string connectError: ""
  property var selected: ({ssid: "protected"})
  property string view: "list"
  property string script: "wifi.sh"
  property var calls: []
  QtObject { id: connectProc; property var environment: ({}) }
  QtObject { id: hiddenProc; property var environment: ({}) }
  function run(proc, args) { calls = calls.concat([args]); }
''' + "\n".join(qml_function(source, name)
                for name in ("connect", "connectHidden", "connectTo", "submitPassword")) + '''
  function exercise() {
    hiddenBusy = true;
    connect("open", "");
    connectTo({ssid: "open", secure: false, saved: false});
    const duringHidden = calls.length;
    hiddenBusy = false;
    connectHidden("hidden", "secret");
    connect("open", "");
    const duringConnect = calls.length;
    connectingSsid = "";
    hiddenBusy = false;
    connectTo({ssid: "open", secure: false, saved: false});
    return {duringHidden, duringConnect, calls, connectionBusy};
  }
''', 'return exercise();')
        self.assertEqual(result, {
            "duringHidden": 0,
            "duringConnect": 1,
            "calls": [["--hidden", "hidden"], ["--connect", "open"]],
            "connectionBusy": True,
        })
