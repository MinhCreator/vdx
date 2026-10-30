"""Verify battery actions recover when their backend cannot start."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class BatteryProcessStart(unittest.TestCase):
    def test_failed_action_start_clears_busy_and_reports_error(self):
        source = (SHELL / "modules/battery/BatteryService.qml").read_text()
        process = qml_block(source, "Process {\n    id: actionProc")
        with tempfile.TemporaryDirectory(prefix="shell-battery-start-") as tmp:
            root = Path(tmp)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property var busy: 80
  property string actionError: ""
  readonly property string error: actionError
  Process {
    id: actionProc
    property bool started: false
    command: ["/no/such/battery-backend"]
    running: true
            onStarted: started = true
    ''' + qml_block(process, "onRunningChanged:") + '''
  }
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("BATTERY_START_RESULT:" + JSON.stringify({
      busy: root.busy, error: root.error
    }));
    Qt.quit();
  } }
}
''')
            output = run_quickshell(root)
            results = [line.split("BATTERY_START_RESULT:", 1)[1]
                       for line in output.splitlines() if "BATTERY_START_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), {
                "busy": None, "error": "could not start battery action"
            }, output)

    def test_failed_status_start_is_visible_and_stops_loading_state(self):
        source = (SHELL / "modules/battery/BatteryService.qml").read_text()
        process = qml_block(source, "Process {\n    id: statusProc")
        with tempfile.TemporaryDirectory(prefix="shell-battery-status-start-") as tmp:
            root = Path(tmp)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property bool ready: false
  property string statusError: ""
  Process {
    id: statusProc
    property bool started: false
    command: ["/no/such/battery-status-backend"]
    running: true
    onStarted: started = true
    ''' + qml_block(process, "onRunningChanged:") + '''
  }
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("BATTERY_STATUS_RESULT:" + JSON.stringify({
      ready: root.ready, error: root.statusError
    }));
    Qt.quit();
  } }
}
''')
            output = run_quickshell(root)
            results = [line.split("BATTERY_STATUS_RESULT:", 1)[1]
                       for line in output.splitlines() if "BATTERY_STATUS_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), {
                "ready": True, "error": "could not start battery status query"
            }, output)


if __name__ == "__main__":
    unittest.main()
