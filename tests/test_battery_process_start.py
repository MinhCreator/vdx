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
  property string error: ""
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


if __name__ == "__main__":
    unittest.main()
