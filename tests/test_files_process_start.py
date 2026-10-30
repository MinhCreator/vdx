"""Verify the Files folder list recovers when its backend cannot start."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class FilesProcessStart(unittest.TestCase):
    def test_failed_folder_query_clears_loading_and_reports_error(self):
        source = (SHELL / "apps/files/FilesState.qml").read_text()
        process = qml_block(source, "Process {\n    id: listProc")
        process = process.replace(
            "id: listProc",
            'id: listProc\n    command: ["/no/such/files-list-backend"]\n    running: true', 1)
        process = process.replace("property var asked: null", 'property var asked: "/fixture"', 1)
        with tempfile.TemporaryDirectory(prefix="shell-files-list-start-") as tmp:
            root = Path(tmp)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property string path: "/fixture"
  property bool loading: true
  property string error: ""
  function resume(proc) {}
  ''' + process + '''
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("FILES_LIST_START_RESULT:" + JSON.stringify({
      loading: root.loading, error: root.error
    }));
    Qt.quit();
  } }
}
''')
            output = run_quickshell(root)
            results = [line.split("FILES_LIST_START_RESULT:", 1)[1]
                       for line in output.splitlines() if "FILES_LIST_START_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), {
                "loading": False, "error": "could not start folder listing",
            }, output)


if __name__ == "__main__":
    unittest.main()
