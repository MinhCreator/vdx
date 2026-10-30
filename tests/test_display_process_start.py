"""Verify display queries and changes recover when Python cannot start."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class DisplayProcessStart(unittest.TestCase):
    def run_failed_process(self, process, state, result):
        source = (SHELL / "apps/display/DisplayService.qml").read_text()
        block = qml_block(source, "Process {\n    id: " + process)
        with tempfile.TemporaryDirectory(prefix="shell-display-start-") as tmp:
            root = Path(tmp)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property string listError: ""
  property string actionError: ""
  property bool busy: true
  property string working: "scale:fixture-monitor"
  property var pending: 1.25
  property var monitors: []
  property real textFactor: 1
  property var textScales: []
  signal applied()
  function refresh() {}
  Process {
    id: ''' + process + '''
    property bool started: false
    command: ["/no/such/display-backend"]
    running: true
    onStarted: started = true
    ''' + qml_block(block, "onRunningChanged:") + '''
  }
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("DISPLAY_START_RESULT:" + JSON.stringify(''' + state + '''));
    Qt.quit();
  } }
}
''')
            output = run_quickshell(root)
            results = [line.split("DISPLAY_START_RESULT:", 1)[1]
                       for line in output.splitlines() if "DISPLAY_START_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), result, output)

    def test_list_start_failure_is_visible(self):
        self.run_failed_process("listProc", "({error: root.listError})",
                                {"error": "could not start display query"})

    def test_action_start_failure_clears_pending_state(self):
        self.run_failed_process("actProc", "({busy: root.busy, working: root.working, pending: root.pending, error: root.actionError})",
                                {"busy": False, "working": "", "pending": None,
                                 "error": "could not start display change"})


if __name__ == "__main__":
    unittest.main()
