"""Drive the real Save as model and backend without opening the modal UI."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class CaptureSaver(unittest.TestCase):
    def run_saver(self, setup, handlers="", existing=False, blocked=False):
        with tempfile.TemporaryDirectory(prefix="shell-saver-") as tmp:
            root = Path(tmp)
            (root / "apps/capture").mkdir(parents=True)
            (root / "kit").mkdir()
            (root / "scripts").mkdir()
            shutil.copy(SHELL / "apps/capture/CaptureSaver.qml", root / "apps/capture/CaptureSaver.qml")
            shutil.copy(SHELL / "kit/reply.js", root / "kit/reply.js")
            for name in ("backend.py", "capture.py"):
                shutil.copy(SHELL / "scripts" / name, root / "scripts" / name)
            source = root / "temporary.png"
            source.write_text("new capture")
            target = root / "output.png"
            if existing:
                target.write_text("old capture")
            if blocked:
                (root / "blocked").write_text("not a directory")
                target = root / "blocked/output.png"
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "apps/capture"
Scope {
  id: root
  property string source: "''' + str(source) + '''"
  property string target: "''' + str(target) + '''"
  property var errors: []
  function check(value, message) { if (!value) errors = errors.concat([message]); }
  function done() { console.warn("SAVE_RESULT:" + JSON.stringify(errors)); Qt.quit(); }
  CaptureSaver {
    id: saver
    script: "''' + str(root / "scripts/capture.py") + '''"
    ''' + handlers + '''
  }
  Component.onCompleted: {
    ''' + setup + '''
  }
  Timer { interval: 5000; running: true; onTriggered: { root.check(false, "timeout"); root.done(); } }
}
''')
            output = run_quickshell(root)
            lines = [line.split("SAVE_RESULT:", 1)[1] for line in output.splitlines() if "SAVE_RESULT:" in line]
            self.assertEqual(len(lines), 1, output)
            self.assertEqual(json.loads(lines[0]), [], output)
            return source.exists(), target.read_text() if target.is_file() else None

    def test_failed_save_keeps_the_dialog_and_source(self):
        source_exists, _ = self.run_saver('''saver.offer({kind: "shot", tmp: root.source, path: root.target});
          saver.confirm(root.target);''',
          '''onBusyChanged: if (!busy && error) {
            root.check(pending !== null, "failed save discarded its request");
            root.check(!replacing, "unrelated failure requested replacement"); root.done();
          }''', blocked=True)
        self.assertTrue(source_exists)

    def test_existing_file_requires_a_second_confirmation(self):
        source_exists, content = self.run_saver('''saver.offer({kind: "video", tmp: root.source, path: root.target});
          saver.confirm(root.target);''',
          '''onBusyChanged: if (!busy && error) {
            root.check(pending !== null && replacing, "missing replacement confirmation");
            confirm(root.target);
          }
          onSaved: { root.check(pending === null && !busy, "save did not finish"); root.done(); }''', existing=True)
        self.assertFalse(source_exists)
        self.assertEqual(content, "new capture")

    def test_invalid_path_is_visible_and_does_not_close_the_dialog(self):
        source_exists, _ = self.run_saver('''saver.offer({kind: "shot", tmp: root.source, path: root.target});
          saver.confirm(""); root.check(saver.error !== "" && saver.pending !== null && !saver.busy, "invalid path accepted");
          saver.edited(); root.check(saver.error === "" && !saver.replacing, "editing did not clear the error");
          Qt.callLater(root.done);''')
        self.assertTrue(source_exists)

    def test_dismissing_a_video_saves_to_the_original_default(self):
        source_exists, content = self.run_saver('''saver.offer({kind: "video", tmp: root.source, path: root.target});
          saver.dismiss();''', 'onSaved: root.done()')
        self.assertFalse(source_exists)
        self.assertEqual(content, "new capture")

    def test_escape_does_not_confirm_replacing_a_video(self):
        source_exists, content = self.run_saver('''saver.offer({kind: "video", tmp: root.source, path: root.target});
          saver.dismiss();''',
          '''property int conflicts: 0
          onBusyChanged: if (!busy && error) {
            conflicts++;
            root.check(replacing && pending !== null, "missing replacement prompt");
            if (conflicts === 1) dismiss(); else root.done();
          }
          onSaved: { root.check(false, "Escape replaced an existing file"); root.done(); }''', existing=True)
        self.assertTrue(source_exists)
        self.assertEqual(content, "old capture")

    def test_dismissing_a_shot_removes_only_its_temporary_file(self):
        source_exists, content = self.run_saver('''saver.offer({kind: "shot", tmp: root.source, path: root.target});
          saver.dismiss();''', 'onBusyChanged: if (!busy && pending === null) root.done()')
        self.assertFalse(source_exists)
        self.assertIsNone(content)

    def test_a_second_request_does_not_replace_the_first(self):
        source_exists, _ = self.run_saver('''saver.offer({kind: "shot", tmp: root.source, path: root.target});
          saver.offer({kind: "shot", tmp: root.source + ".other", path: root.target + ".second"});
          root.check(saver.pending.path === root.target, "first request was replaced");
          saver.dismiss();''',
          '''onBusyChanged: if (!busy) {
            if (pending) {
              root.check(pending.path === root.target + ".second", "queued request was lost"); dismiss();
            } else root.done();
          }''')
        self.assertFalse(source_exists)

    def test_clipboard_failure_keeps_the_only_copy_when_skipped(self):
        source_exists, _ = self.run_saver('''saver.offer({kind: "shot", tmp: root.source, path: root.target,
            copyFailed: true, error: "Clipboard failed"});
          root.check(saver.error !== "", "copy error hidden");
          saver.dismiss(); root.check(saver.pending === null, "skip did not close the dialog");
          Qt.callLater(root.done);''')
        self.assertTrue(source_exists)


if __name__ == "__main__":
    unittest.main()
