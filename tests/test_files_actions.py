"""Run the production file-action queue with real child processes, offscreen.

The fixture has its own config, runtime and state directories; the fake backend
only prints replies. It cannot operate on the user's files or start the shell UI.
"""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class FileActions(unittest.TestCase):
    def run_queue(self, requests, callback="", cancel=False):
        with tempfile.TemporaryDirectory(prefix="shell-actions-") as tmp:
            root = Path(tmp)
            (root / "apps/files").mkdir(parents=True)
            (root / "kit").mkdir()
            shutil.copy(SHELL / "apps/files/FilesActions.qml", root / "apps/files/FilesActions.qml")
            shutil.copy(SHELL / "kit/reply.js", root / "kit/reply.js")
            (root / "backend.py").write_text('''import json, sys, time
mode = sys.argv[1]
if mode == "slow": time.sleep(0.15)
if mode == "empty": sys.exit(1)
if mode == "invalid": print("null"); sys.exit(1)
print(json.dumps({"progress": 1, "of": 1, "name": mode}), flush=True)
print(json.dumps({"ok": True, "mode": mode}), flush=True)
if mode == "crash": sys.exit(1)
''')
            submit = "\n".join(
                f"actions.submit({{done: 'created', id: {i}}}, [{json.dumps(mode)}]);"
                for i, mode in enumerate(requests))
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "apps/files"
Scope {
  id: root
  property var results: []
  FilesActions {
    id: actions
    script: "''' + str(root / "backend.py") + '''"
    onFinished: (result, request, cancelled) => {
      root.results = root.results.concat([{id: request.id, result: result, cancelled: cancelled}]);
      ''' + callback + '''
    }
    onBusyChanged: if (!busy && root.results.length) {
      console.warn("QUEUE_RESULT:" + JSON.stringify(root.results));
      Qt.quit();
    }
  }
  Component.onCompleted: {
    ''' + submit + '''
  }
  Timer { interval: 5000; running: true; onTriggered: { console.warn("QUEUE_TIMEOUT"); Qt.quit(); } }
''' + ('Timer { interval: 40; running: true; onTriggered: actions.cancel() }' if cancel else '') + '''
}
''')
            output = run_quickshell(root)
            lines = [line.split("QUEUE_RESULT:", 1)[1] for line in output.splitlines() if "QUEUE_RESULT:" in line]
            self.assertEqual(len(lines), 1, output)
            return json.loads(lines[0])

    def test_every_queued_operation_runs_in_order(self):
        results = self.run_queue(["slow", "second", "third"])
        self.assertEqual([r["id"] for r in results], [0, 1, 2])
        self.assertEqual([r["result"]["mode"] for r in results], ["slow", "second", "third"])

    def test_missing_reply_does_not_reuse_previous_success(self):
        results = self.run_queue(["success", "empty", "last"])
        self.assertTrue(results[0]["result"]["ok"])
        self.assertFalse(results[1]["result"]["ok"])
        self.assertEqual(results[1]["result"]["error"], "no answer from files.py")
        self.assertTrue(results[2]["result"]["ok"])

    def test_invalid_reply_and_nonzero_exit_fail(self):
        results = self.run_queue(["invalid", "crash"])
        self.assertFalse(results[0]["result"]["ok"])
        self.assertFalse(results[1]["result"]["ok"])

    def test_completion_can_enqueue_without_replacing_pending_work(self):
        results = self.run_queue(["first", "second"],
                                 'if (request.id === 0) actions.submit({done: "created", id: 2}, ["third"]);')
        self.assertEqual([r["id"] for r in results], [0, 1, 2])

    def test_cancelling_one_operation_keeps_the_next(self):
        results = self.run_queue(["slow", "next"], cancel=True)
        self.assertEqual([r["id"] for r in results], [0, 1])
        self.assertTrue(results[0]["cancelled"])
        self.assertFalse(results[1]["cancelled"])
        self.assertTrue(results[1]["result"]["ok"])


if __name__ == "__main__":
    unittest.main()
