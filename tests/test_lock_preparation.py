"""Prepare lock backgrounds offscreen using a fake grim, without locking."""
from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import signal
import tempfile
import unittest

from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs") and shutil.which("timeout"), "Quickshell/coreutils are not installed")
class LockPreparation(unittest.TestCase):
    def prepare(self, mode="success", missing_command=False, repeat=False):
        with tempfile.TemporaryDirectory(prefix="shell-lock-preparation-") as tmp:
            root = Path(tmp)
            (root / "lock").mkdir()
            (root / "bin").mkdir()
            fake = root / "bin/grim"
            fake.write_text('''#!/usr/bin/python3
import os, signal, sys, time
from pathlib import Path
mode = os.environ["LOCK_TEST_MODE"]
Path(os.environ["LOCK_TEST_PID_DIR"], sys.argv[-2]).write_text(str(os.getpid()))
if mode == "ignore-term": signal.signal(signal.SIGTERM, signal.SIG_IGN)
if mode in ("hang", "ignore-term"): time.sleep(10)
if mode == "fail": sys.exit(1)
Path(sys.argv[-1]).write_bytes(b"test image")
''')
            fake.chmod(0o755)
            source = (SHELL / "apps/lock/LockPreparation.qml").read_text()
            if missing_command:
                self.assertEqual(source.count('"timeout"'), 1)
                source = source.replace('"timeout"', json.dumps(str(root / "absent-timeout")))
            (root / "lock/LockPreparation.qml").write_text(source)
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "lock"
Scope {
  id: root
  property int completions: 0
  property bool rejectedOverlap: false
  property double started: Date.now()
  LockPreparation {
    id: preparation
    onReady: {
      root.completions++;
      if (''' + str(repeat).lower() + ''' && root.completions === 1) {
        preparation.prepare("''' + str(root / "images") + '''", ["one", "two"]);
      }
    }
  }
  Component.onCompleted: {
    preparation.prepare("''' + str(root / "images") + '''", ["one", "two"]);
    root.rejectedOverlap = !preparation.prepare("''' + str(root / "other") + '''", ["unexpected"]);
  }
  Timer {
    interval: 20; running: true; repeat: true
    onTriggered: if (root.completions === ''' + ("2" if repeat else "1") + ''') {
      console.warn("PREPARATION_RESULT:" + JSON.stringify({
        completions: root.completions, busy: preparation.busy,
        rejected: root.rejectedOverlap, elapsed: Date.now() - root.started
      })); Qt.quit();
    }
  }
  Timer { interval: 5000; running: true; onTriggered: Qt.quit() }
}
''')
            (root / "pids").mkdir()
            output = run_quickshell(root, environment={
                "PATH": str(root / "bin") + os.pathsep + os.environ["PATH"],
                "LOCK_TEST_MODE": mode,
                "LOCK_TEST_PID_DIR": str(root / "pids"),
            })
            lines = [line.split("PREPARATION_RESULT:", 1)[1] for line in output.splitlines()
                     if "PREPARATION_RESULT:" in line]
            self.assertEqual(len(lines), 1, output)
            result = json.loads(lines[0])
            survivors = []
            for path in (root / "pids").iterdir():
                pid = int(path.read_text())
                process = Path(f"/proc/{pid}/stat")
                try:
                    running = process.read_text().split(")", 1)[1].split()[0] != "Z"
                except FileNotFoundError:
                    running = False
                if running:
                    survivors.append(pid)
                    try:
                        os.kill(pid, signal.SIGKILL)
                    except ProcessLookupError:
                        pass
            result["survivors"] = survivors
            result["images"] = sorted(p.name for p in (root / "images").glob("*.jpg"))
            self.assertFalse((root / "other").exists())
            return result

    def test_parallel_snapshots_finish_and_reject_overlapping_request(self):
        result = self.prepare()
        self.assertTrue(result["rejected"])
        self.assertFalse(result["busy"])
        self.assertEqual(result["images"], ["one.jpg", "two.jpg"])

    def test_failed_snapshots_still_finish(self):
        result = self.prepare("fail")
        self.assertEqual(result["completions"], 1)
        self.assertFalse(result["busy"])
        self.assertEqual(result["images"], [])

    def test_hung_snapshots_have_a_shared_deadline(self):
        result = self.prepare("hang")
        self.assertLess(result["elapsed"], 3000)
        self.assertFalse(result["busy"])
        self.assertEqual(result["images"], [])

    def test_force_kill_handles_screenshot_ignoring_term(self):
        result = self.prepare("ignore-term")
        self.assertLess(result["elapsed"], 3000)
        self.assertFalse(result["busy"])
        self.assertEqual(result["survivors"], [])

    def test_missing_command_uses_fallback_once(self):
        result = self.prepare(missing_command=True)
        self.assertEqual(result["completions"], 1)
        self.assertLess(result["elapsed"], 3000)
        self.assertFalse(result["busy"])

    def test_completion_listener_can_prepare_again(self):
        result = self.prepare(repeat=True)
        self.assertEqual(result["completions"], 2)
        self.assertFalse(result["busy"])
