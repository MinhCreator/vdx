"""Exercise audio port changes and error reporting without PipeWire actions."""
from __future__ import annotations

import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block, qml_function
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class AudioPortAction(unittest.TestCase):
    def run_selection(self, fail_to_start=False, exit_code=23):
        source = (SHELL / "modules/audio/AudioService.qml").read_text()
        with tempfile.TemporaryDirectory(prefix="shell-audio-port-") as tmp:
            root = Path(tmp)
            path = root / "bin"
            path.mkdir()
            pactl = path / "pactl"
            if fail_to_start:
                pactl.write_text('#!/no/such/interpreter\n')
            else:
                pactl.write_text('#!/bin/sh\nprintf \'%s\\n\' "$@" > "$PACTL_LOG"\nexit '
                                + str(exit_code) + '\n')
            pactl.chmod(0o755)
            process = qml_block(source, "Process {\n    id: portActionProc")
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
Scope {
  id: root
  property bool portBusy: false
  property string portError: ""
  property string portErrorTarget: ""
  property var selectedNode: null
  function setSink(node) { selectedNode = node; }
  function setSource(node) { selectedNode = node; }
  QtObject { id: portRefresh; function restart() {} }
  ''' + qml_function(source, "select") + process + '''
  Timer { interval: 100; running: true; onTriggered: {
    root.select({node: {type: PwNodeType.AudioSink, name: "fixture-sink"},
                 port: "analog-output-headphones"});
  } }
  Timer { interval: 300; running: true; onTriggered: {
    console.warn("AUDIO_PORT_RESULT:" + JSON.stringify({
      busy: root.portBusy, error: root.portError, target: root.portErrorTarget,
      selected: root.selectedNode?.name ?? ""
    }));
    Qt.quit();
  } }
}
''')
            env = {"PATH": str(path) + os.pathsep + os.environ["PATH"],
                   "PACTL_LOG": str(root / "pactl.log")}
            output = run_quickshell(root, timeout=4, environment=env)
            results = [line.split("AUDIO_PORT_RESULT:", 1)[1]
                       for line in output.splitlines() if "AUDIO_PORT_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), {
                "busy": False,
                "error": "could not start changing the audio port" if fail_to_start
                         else "" if exit_code == 0 else "could not change the audio port",
                "target": "output",
                "selected": "fixture-sink",
            }, output)
            if not fail_to_start:
                self.assertEqual((root / "pactl.log").read_text().splitlines(),
                                 ["set-sink-port", "fixture-sink", "analog-output-headphones"])

    def test_nonzero_pactl_exit_clears_busy_and_reports_error(self):
        self.run_selection()

    def test_pactl_launch_failure_clears_busy_and_reports_error(self):
        self.run_selection(fail_to_start=True)

    def test_success_clears_busy_and_error(self):
        self.run_selection(exit_code=0)


if __name__ == "__main__":
    unittest.main()
