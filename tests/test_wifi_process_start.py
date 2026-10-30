"""Verify Wi-Fi scans recover when their backend cannot start."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class WifiProcessStart(unittest.TestCase):
    def test_radio_backend_failure_restores_state_and_shows_reply_error(self):
        source = (SHELL / "modules/wifi/WifiService.qml").read_text()
        callback = qml_block(source[source.index("id: radioProc"):], "onStreamFinished:").split(
            ":", 1)[1]
        with tempfile.TemporaryDirectory(prefix="shell-wifi-radio-reply-") as tmp:
            root = Path(tmp)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
Scope {
  id: root
  property bool radioOn: false
  property bool toggling: true
  property string radioError: ""
  property string text: ""
  function parse(text) { return JSON.parse(text); }
  function refreshStatus() {}
  QtObject { id: radioSettle; function restart() {} }
  function complete() ''' + callback + '''
  Timer { interval: 10; running: true; onTriggered: {
    text = JSON.stringify({ok: false, error: "radio denied"});
    complete();
    console.warn("WIFI_RADIO_REPLY_RESULT:" + JSON.stringify({
      radioOn: root.radioOn, toggling: root.toggling, error: root.radioError
    }));
    Qt.quit();
  } }
}
''')
            output = run_quickshell(root)
            results = [line.split("WIFI_RADIO_REPLY_RESULT:", 1)[1]
                       for line in output.splitlines() if "WIFI_RADIO_REPLY_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), {
                "radioOn": True, "toggling": False, "error": "radio denied",
            }, output)

    def test_failed_radio_start_restores_state_and_reports_error(self):
        source = (SHELL / "modules/wifi/WifiService.qml").read_text()
        process = qml_block(source, "Process {\n    id: radioProc")
        process = process.replace("id: radioProc", '''id: radioProc
    command: ["/no/such/wifi-radio-backend"]
    running: true''', 1)
        with tempfile.TemporaryDirectory(prefix="shell-wifi-radio-start-") as tmp:
            root = Path(tmp)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property bool radioOn: false
  property bool toggling: true
  property string radioError: ""
  function refreshStatus() {}
  function scan() {}
  QtObject { id: radioSettle; function restart() {} }
  ''' + process + '''
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("WIFI_RADIO_START_RESULT:" + JSON.stringify({
      radioOn: root.radioOn, toggling: root.toggling, error: root.radioError
    }));
    Qt.quit();
  } }
}
''')
            output = run_quickshell(root)
            results = [line.split("WIFI_RADIO_START_RESULT:", 1)[1]
                       for line in output.splitlines() if "WIFI_RADIO_START_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), {
                "radioOn": True, "toggling": False,
                "error": "could not start Wi-Fi radio request",
            }, output)

    def test_failed_action_starts_clear_busy_and_report_errors(self):
        source = (SHELL / "modules/wifi/WifiService.qml").read_text()
        cases = (
            ("dnsSetProc", "dnsBusy", "dnsError", "could not start DNS update"),
            ("setSavedProc", "savedBusy", "saveError", "could not start network update"),
            ("ethernetActionProc", "ethernetBusy", "ethernetError",
             "could not start wired connection change"),
            ("hotspotActionProc", "hotspotBusy", "hotspotError",
             "could not start hotspot change"),
        )
        for process_id, busy, error, expected_error in cases:
            with self.subTest(process=process_id), tempfile.TemporaryDirectory(
                    prefix="shell-wifi-action-start-") as tmp:
                root = Path(tmp)
                process = qml_block(source, f"Process {{\n    id: {process_id}")
                process = process.replace(
                    f"id: {process_id}",
                    f'id: {process_id}\n    command: ["/no/such/wifi-action"]\n    running: true', 1)
                (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property bool dnsBusy: true
  property string dnsError: ""
  property bool savedBusy: true
  property string saveError: ""
  property bool ethernetBusy: true
  property string ethernetError: ""
  property bool hotspotBusy: true
  property string hotspotError: ""
  function refreshDns() {}
  function refreshSaved() {}
  function refreshEthernet() {}
  function refreshHotspot() {}
  function parse(text) { return JSON.parse(text); }
  ''' + process + '''
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("WIFI_ACTION_START_RESULT:" + JSON.stringify({
      busy: root.''' + busy + ''', error: root.''' + error + '''
    }));
    Qt.quit();
  } }
}
''')
                output = run_quickshell(root)
                results = [line.split("WIFI_ACTION_START_RESULT:", 1)[1]
                           for line in output.splitlines() if "WIFI_ACTION_START_RESULT:" in line]
                self.assertEqual(len(results), 1, output)
                self.assertEqual(json.loads(results[0]), {
                    "busy": False, "error": expected_error,
                }, output)

    def test_failed_scan_start_clears_busy_and_reports_error(self):
        source = (SHELL / "modules/wifi/WifiService.qml").read_text()
        process = qml_block(source, "Process {\n    id: scanProc")
        process = process.replace(
            'command: ["bash", root.script, "--scan"]',
            'command: ["/no/such/wifi-scan-backend"]')
        process = process.replace("id: scanProc", "id: scanProc\n    running: true", 1)
        with tempfile.TemporaryDirectory(prefix="shell-wifi-scan-start-") as tmp:
            root = Path(tmp)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property bool scanning: true
  property string scanError: ""
  property var networks: []
  function refreshNetworks() {}
  ''' + process + '''
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("WIFI_SCAN_START_RESULT:" + JSON.stringify({
      scanning: root.scanning, error: root.scanError
    }));
    Qt.quit();
  } }
}
''')
            output = run_quickshell(root)
            results = [line.split("WIFI_SCAN_START_RESULT:", 1)[1]
                       for line in output.splitlines() if "WIFI_SCAN_START_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), {
                "scanning": False, "error": "could not start Wi-Fi scan"
            }, output)


if __name__ == "__main__":
    unittest.main()
