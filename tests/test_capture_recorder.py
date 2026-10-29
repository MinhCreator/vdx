"""Exercise the recording lifecycle with a fake recorder, never the desktop."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class CaptureRecorder(unittest.TestCase):
    def run_capture(self, setup, handlers="", extra=""):
        with tempfile.TemporaryDirectory(prefix="shell-recorder-") as tmp:
            root = Path(tmp)
            shutil.copy(SHELL / "apps/capture/CaptureRecorder.qml", root / "CaptureRecorder.qml")
            (root / "fake.py").write_text('''import pathlib, signal, sys, time
mode, path = sys.argv[1:]
if mode == "fail":
    print("gsr error: fake recorder failed", file=sys.stderr)
    print("cleanup", file=sys.stderr)
    sys.exit(1)
if mode == "empty": pathlib.Path(path).touch(); sys.exit(0)
signal.signal(signal.SIGINT, lambda *_: sys.exit(0))
signal.signal(signal.SIGUSR2, lambda *_: None)
pathlib.Path(path).write_bytes(b"fake-video")
if mode == "wait":
    while True: time.sleep(0.01)
''')
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
Scope {
  id: root
  property var errors: []
  property var results: []
  function check(value, message) { if (!value) errors = errors.concat([message]); }
  function done() {
    console.warn("CAPTURE_RESULT:" + JSON.stringify({errors: errors, results: results}));
    Qt.quit();
  }
  function request(mode, suffix) {
    const file = "''' + str(root) + '''/" + suffix + ".mp4";
    return {file: file, path: "original/" + suffix, ask: true, fps: 60, audio: "mic",
      command: ["python3", "''' + str(root / "fake.py") + '''", mode, file]};
  }
  CaptureRecorder {
    id: recorder
    startDelay: 60
    ''' + handlers + '''
  }
  Component.onCompleted: { ''' + setup + ''' }
  ''' + extra + '''
  Timer { interval: 5000; running: true; onTriggered: { root.check(false, "timeout"); root.done(); } }
}
''')
            output = run_quickshell(root)
            lines = [line.split("CAPTURE_RESULT:", 1)[1] for line in output.splitlines() if "CAPTURE_RESULT:" in line]
            self.assertEqual(len(lines), 1, output)
            result = json.loads(lines[0])
            self.assertEqual(result["errors"], [], output)
            return result["results"]

    def test_stop_cancels_the_delayed_start(self):
        self.run_capture('''recorder.start(root.request("wait", "cancelled"));
          root.check(recorder.starting && recorder.busy, "start must reserve the session");
          recorder.stop(); root.check(!recorder.busy && !recorder.starting, "cancel must release the session");''',
          'onAboutToStart: root.check(false, "cancelled recorder started")',
          'Timer { interval: 180; running: true; onTriggered: root.done() }')

    def test_request_and_command_are_snapshotted(self):
        result = self.run_capture('''const capture = root.request("success", "original");
          recorder.start(capture); capture.ask = false; capture.path = "changed"; capture.fps = 10;
          capture.command[2] = "fail";
          root.check(!recorder.start(root.request("success", "overlap")), "overlap accepted");''',
          '''onCompleted: capture => {
            root.check(!recorder.busy, "completion must release the session");
            root.results = [capture]; root.done();
          }
          onRecordingChanged: if (!recording && busy)
            root.check(!start(root.request("success", "checking-overlap")), "verification overlap accepted")
          onFailed: (capture, message) => { root.check(false, message); root.done(); }''')
        self.assertEqual(result[0]["path"], "original/original")
        self.assertTrue(result[0]["ask"])
        self.assertEqual(result[0]["fps"], 60)

    def test_empty_output_fails_even_with_zero_exit(self):
        self.run_capture('recorder.start(root.request("empty", "empty"));',
          '''onCompleted: { root.check(false, "empty output accepted"); root.done(); }
          onFailed: { root.check(!recorder.busy, "failure must release the session"); root.done(); }''')

    def test_failure_uses_the_recorders_error_line(self):
        result = self.run_capture('recorder.start(root.request("fail", "failed"));',
          '''onCompleted: { root.check(false, "failed recorder accepted"); root.done(); }
          onFailed: (capture, message) => { root.results = [message]; root.done(); }''')
        self.assertEqual(result, ["fake recorder failed"])

    def test_completion_can_start_a_new_session(self):
        result = self.run_capture('recorder.start(root.request("success", "first"));',
          '''onCompleted: capture => {
            root.results = root.results.concat([capture.path]);
            if (root.results.length === 1) root.check(recorder.start(root.request("success", "second")), "restart rejected");
            else root.done();
          }
          onFailed: (capture, message) => { root.check(false, message); root.done(); }''')
        self.assertEqual(result, ["original/first", "original/second"])

    def test_pause_resume_and_stop_keep_the_output(self):
        self.run_capture('recorder.start(root.request("wait", "paused"));',
          '''onCompleted: { root.check(!recorder.paused, "pause survived completion"); root.done(); }
          onFailed: (capture, message) => { root.check(false, message); root.done(); }''',
          '''Timer { interval: 500; running: true; onTriggered: {
            root.check(recorder.recording, "recorder did not start");
            root.check(!recorder.start(root.request("success", "overlap")), "running overlap accepted");
            recorder.togglePause(); root.check(recorder.paused, "pause ignored"); resume.start();
          } }
          Timer { id: resume; interval: 100; onTriggered: {
            recorder.togglePause(); root.check(!recorder.paused, "resume ignored");
            root.check(recorder.pausedFor >= 80, "pause time not counted"); recorder.stop();
          } }''')


if __name__ == "__main__":
    unittest.main()
