"""Exercise root-action lifecycle with a fake pkexec that never runs commands."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class RootService(unittest.TestCase):
    def run_action(self, setup, callback="", pending_callback=""):
        with tempfile.TemporaryDirectory(prefix="shell-root-") as tmp:
            root = Path(tmp)
            (root / "auth").mkdir()
            fake = root / "fake-pkexec"
            fake.write_text('''#!/usr/bin/python3
import sys, time
script = sys.argv[-1]
if "slow-action" in script: time.sleep(0.15)
if "error-action" in script:
    print("first detail\\noperation failed", file=sys.stderr)
    sys.exit(1)
if "denied-action" in script: sys.exit(126)
''')
            fake.chmod(0o755)
            source = (SHELL / "apps/auth/RootService.qml").read_text()
            # Only the executable is substituted; no supplied shell is executed.
            self.assertEqual(source.count('"pkexec"'), 2, "update the isolated command substitution")
            source = source.replace('"pkexec"', json.dumps(str(fake)))
            (root / "auth/RootService.qml").write_text(source)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "auth"
Scope {
  id: root
  property var results: []
  Connections {
    target: RootService
    function onPendingChanged() { ''' + pending_callback + ''' }
    function onFinished(tag, ok, error) {
      root.results = root.results.concat([{tag: tag, ok: ok, error: error}]);
      ''' + callback + '''
    }
  }
  Component.onCompleted: { ''' + setup + ''' }
  Timer {
    interval: 10; running: true; repeat: true
    onTriggered: if (root.results.length && !RootService.pending && !RootService.running) {
      console.warn("ROOT_RESULT:" + JSON.stringify(root.results)); Qt.quit();
    }
  }
  Timer { interval: 5000; running: true; onTriggered: Qt.quit() }
}
''')
            output = run_quickshell(root)
            results = [line.split("ROOT_RESULT:", 1)[1] for line in output.splitlines()
                       if "ROOT_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            return json.loads(results[0])

    def test_cancel_pending_action_and_reject_overlapping_request(self):
        results = self.run_action('''
          RootService.request("test", "first", [], "first", "first", false);
          if (RootService.request("test", "other", [], "other", "other", true))
            throw new Error("accepted overlapping request");
          RootService.cancel();
        ''')
        self.assertEqual(results, [{"tag": "first", "ok": False, "error": "cancelled"}])

    def test_report_backend_error(self):
        results = self.run_action('RootService.request("test", "error", [], "error-action", "failed", true);')
        self.assertEqual(results, [{"tag": "failed", "ok": False, "error": "operation failed"}])

    def test_report_authorization_failure(self):
        results = self.run_action('RootService.request("test", "denied", [], "denied-action", "denied", true);')
        self.assertEqual(results[0]["tag"], "denied")
        self.assertFalse(results[0]["ok"])
        self.assertIn("not authorized", results[0]["error"])

    def test_finished_callback_can_start_and_cancel_the_next_action(self):
        results = self.run_action(
            'RootService.request("test", "first", [], "first", "first", true);',
            '''if (tag === "first") {
              RootService.request("test", "next", [], "slow-action", "next", true);
              RootService.stop();
            }''')
        self.assertEqual(results, [{"tag": "first", "ok": True, "error": ""},
                                   {"tag": "next", "ok": False, "error": "cancelled"}])

    def test_cancel_keeps_original_tag_when_idle_listener_submits_next(self):
        results = self.run_action(
            '''RootService.request("test", "first", [], "first", "first", false);
               RootService.cancel();''',
            pending_callback='''if (!RootService.pending && !RootService.running && RootService.tag === "first")
              RootService.request("test", "next", [], "next", "next", true);''')
        self.assertEqual(results, [{"tag": "first", "ok": False, "error": "cancelled"},
                                   {"tag": "next", "ok": True, "error": ""}])

    def test_next_success_does_not_reuse_previous_error(self):
        results = self.run_action(
            'RootService.request("test", "first", [], "error-action", "first", true);',
            '''if (tag === "first") RootService.request("test", "next", [], "next", "next", true);''')
        self.assertFalse(results[0]["ok"])
        self.assertEqual(results[1], {"tag": "next", "ok": True, "error": ""})
