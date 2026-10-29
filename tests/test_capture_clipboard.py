"""The tracked clipboard phase releases its screenshot only after completion."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class CaptureClipboard(unittest.TestCase):
    def test_copy_snapshots_its_request_and_rejects_overlap(self):
        with tempfile.TemporaryDirectory(prefix="capture-clipboard-") as tmp:
            root = Path(tmp)
            (root / "apps/capture").mkdir(parents=True)
            (root / "kit").mkdir()
            shutil.copy(SHELL / "apps/capture/CaptureClipboard.qml", root / "apps/capture/CaptureClipboard.qml")
            shutil.copy(SHELL / "kit/reply.js", root / "kit/reply.js")
            (root / "fake.py").write_text('''import json, sys, time
assert sys.argv[1:] == ["clipboard", "original.png"]
time.sleep(0.08)
print(json.dumps({"ok": True}))
''')
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import "apps/capture"
Scope {
  id: root
  property bool overlapAccepted: false
  CaptureClipboard {
    id: clipboard
    script: "''' + str(root / "fake.py") + '''"
    onCompleted: (capture, result) => {
      console.warn("CLIPBOARD_RESULT:" + JSON.stringify({capture: capture, result: result,
        busy: busy, overlap: root.overlapAccepted}));
      Qt.quit();
    }
  }
  Component.onCompleted: {
    const capture = {file: "original.png", target: "ask"};
    clipboard.copy(capture); capture.file = "changed.png"; capture.target = "clipboard";
    root.overlapAccepted = clipboard.copy(capture);
  }
  Timer { interval: 5000; running: true; onTriggered: Qt.quit() }
}
''')
            output = run_quickshell(root)
            lines = [line.split("CLIPBOARD_RESULT:", 1)[1] for line in output.splitlines() if "CLIPBOARD_RESULT:" in line]
            self.assertEqual(len(lines), 1, output)
            reply = json.loads(lines[0])
            self.assertTrue(reply["result"]["ok"], output)
            self.assertEqual(reply["capture"], {"file": "original.png", "target": "ask"})
            self.assertFalse(reply["busy"])
            self.assertFalse(reply["overlap"])


if __name__ == "__main__":
    unittest.main()
