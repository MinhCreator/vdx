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
