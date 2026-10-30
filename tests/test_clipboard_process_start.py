"""Verify clipboard queries and actions report process-start failures."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class ClipboardProcessStart(unittest.TestCase):
    def test_history_and_action_start_failures_are_visible(self):
        source = (SHELL / "apps/clipboard/ClipboardService.qml").read_text()
        cases = (
            ("listProc", "could not start clipboard history query"),
            ("actionProc", "could not start clipboard action"),
        )
        for process_id, expected in cases:
            with self.subTest(process=process_id), tempfile.TemporaryDirectory(
                    prefix="shell-clipboard-start-") as tmp:
                root = Path(tmp)
                process = qml_block(source, f"Process {{\n    id: {process_id}")
                process = process.replace(
                    f"id: {process_id}",
                    f'id: {process_id}\n    command: ["/no/such/{process_id}-backend"]\n    running: true', 1)
                (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property string error: ""
  property var entries: [{id: "existing"}]
  function parse(text, fallback) { try { return JSON.parse(text); } catch (e) { return fallback; } }
  function refresh() {}
  ''' + process + '''
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("CLIPBOARD_START_RESULT:" + JSON.stringify(root.error));
    Qt.quit();
  } }
}
''')
                output = run_quickshell(root)
                results = [line.split("CLIPBOARD_START_RESULT:", 1)[1]
                           for line in output.splitlines() if "CLIPBOARD_START_RESULT:" in line]
                self.assertEqual(len(results), 1, output)
                self.assertEqual(json.loads(results[0]), expected, output)


if __name__ == "__main__":
    unittest.main()
