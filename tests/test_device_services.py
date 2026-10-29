"""Run device state/action logic against local objects, without hardware access."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
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
            output = run_quickshell(root)
            results = [line.split("DEVICE_RESULT:", 1)[1]
                       for line in output.splitlines() if "DEVICE_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            return json.loads(results[0])

    def battery(self, action):
        source = (SHELL / "modules/battery/BatteryService.qml").read_text()
        definitions = '''
  property var busy: null
  property string error: ""
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

    def test_battery_waits_for_a_valid_status_shape(self):
        source = (SHELL / "modules/battery/BatteryService.qml").read_text()
        callback = handler(source, "statusProc").replace(
            'Reply.parse(text, "battery.sh", null)', "JSON.parse(text)")
        result = self.evaluate('''
  property var info: ({})
  property bool ready: false
  property string text: ""
  function parse(text) { return JSON.parse(text); }
  function complete(text) ''' + callback, '''
          complete(JSON.stringify({ok: false, error: "backend missing"}));
          const afterError = ready;
          complete(JSON.stringify({present: false}));
          return {afterError, ready, info};
        ''')
        self.assertEqual(result, {"afterError": False, "ready": True, "info": {"present": False}})

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
