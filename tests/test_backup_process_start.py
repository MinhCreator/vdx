"""Verify Backup status loading recovers when its backend cannot start."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class BackupProcessStart(unittest.TestCase):
    def test_failed_status_start_stops_loading_and_reports_error(self):
        source = (SHELL / "apps/backup/BackupService.qml").read_text()
        process = qml_block(source, "Process {\n    id: statusProc")
        process = process.replace(
            'command: ["python3", root.script, "--json", "status"]',
            'command: ["/no/such/backup-status-backend"]')
        process = process.replace("id: statusProc", "id: statusProc\n    running: true", 1)
        with tempfile.TemporaryDirectory(prefix="shell-backup-status-start-") as tmp:
            root = Path(tmp)
            (root / "kit").mkdir()
            shutil.copy(SHELL / "kit/reply.js", root / "kit/reply.js")
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
import "kit/reply.js" as Reply
Scope {
  id: root
  property bool loaded: false
  property string loadError: ""
  property string status: ""
  property string message: ""
  function done(ok, text) { status = ok ? "ok" : "error"; message = text; }
  ''' + process + '''
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("BACKUP_STATUS_START_RESULT:" + JSON.stringify({
      loaded: root.loaded, loadError: root.loadError,
      status: root.status, message: root.message
    }));
    Qt.quit();
  } }
}
''')
            output = run_quickshell(root)
            results = [line.split("BACKUP_STATUS_START_RESULT:", 1)[1]
                       for line in output.splitlines() if "BACKUP_STATUS_START_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), {
                "loaded": False,
                "loadError": "could not start backup status query",
                "status": "error",
                "message": "could not start backup status query",
            }, output)


if __name__ == "__main__":
    unittest.main()
