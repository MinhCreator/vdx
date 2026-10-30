"""Verify Capture Save as recovers when the file-operation process cannot start."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class CaptureProcessStart(unittest.TestCase):
    def test_failed_file_operation_start_keeps_request_and_clears_busy(self):
        source = (SHELL / "apps/capture/CaptureSaver.qml").read_text()
        process = qml_block(source, "Process {\n    id: worker")
        process = process.replace(
            "id: worker", 'id: worker\n    command: ["/no/such/capture-backend"]\n    running: true', 1)
        with tempfile.TemporaryDirectory(prefix="shell-capture-start-") as tmp:
            root = Path(tmp)
            (root / "kit").mkdir()
            shutil.copy(SHELL / "kit/reply.js", root / "kit/reply.js")
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import "kit/reply.js" as Reply
Scope {
  id: root
  property string target: "/tmp/capture.png"
  property string operation: "save"
  property bool busy: true
  property string error: ""
  property string overwritePath: ""
  property var pending: ({kind: "video"})
  property var savedRequest: null
  signal saved(var capture, string path)
  function takeNext() { const value = pending; pending = null; return value; }
  Connections { target: root; function onSaved(capture, path) { root.savedRequest = capture; } }
  ''' + process + '''
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("CAPTURE_START_RESULT:" + JSON.stringify({
      busy: root.busy, error: root.error, pending: root.pending !== null
    }));
    Qt.quit();
  } }
}
''')
            output = run_quickshell(root)
            results = [line.split("CAPTURE_START_RESULT:", 1)[1]
                       for line in output.splitlines() if "CAPTURE_START_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), {
                "busy": False,
                "error": "Could not start the capture file operation",
                "pending": True,
            }, output)


if __name__ == "__main__":
    unittest.main()
