"""Verify Packages query state recovers when Python cannot start."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class PackagesProcessStart(unittest.TestCase):
    def test_update_check_and_installed_query_failures_clear_busy_state(self):
        source = (SHELL / "apps/packages/PackagesService.qml").read_text()
        cases = (
            ("checkProc", "checking", "updates", "could not start package update check"),
            ("installedProc", "loading", "installed", "could not start installed package query"),
        )
        for process_id, busy, command, expected in cases:
            with self.subTest(process=process_id), tempfile.TemporaryDirectory(
                    prefix="shell-packages-start-") as tmp:
                root = Path(tmp)
                process = qml_block(source, f"Process {{\n    id: {process_id}")
                process = process.replace(
                    f'command: ["python3", root.script, "{command}"]',
                    'command: ["/no/such/packages-backend"]')
                process = process.replace(
                    f'id: {process_id}',
                    f'id: {process_id}\n    running: true', 1)
                (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property bool checking: ''' + ("true" if busy == "checking" else "false") + '''
  property bool loading: ''' + ("true" if busy == "loading" else "false") + '''
  property string status: ""
  property string message: ""
  function done(ok, text) { status = ok ? "ok" : "error"; message = text; }
  function parse(text) { return JSON.parse(text); }
  ''' + process + '''
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("PACKAGES_START_RESULT:" + JSON.stringify({
      busy: root.''' + busy + ''', status: root.status, message: root.message
    }));
    Qt.quit();
  } }
}
''')
                output = run_quickshell(root)
                results = [line.split("PACKAGES_START_RESULT:", 1)[1]
                           for line in output.splitlines() if "PACKAGES_START_RESULT:" in line]
                self.assertEqual(len(results), 1, output)
                self.assertEqual(json.loads(results[0]), {
                    "busy": False, "status": "error", "message": expected,
                }, output)


if __name__ == "__main__":
    unittest.main()
