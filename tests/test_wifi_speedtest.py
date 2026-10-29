"""Verify cancelled speed tests cannot replace a newer result."""
from __future__ import annotations

import json
from pathlib import Path
import shlex
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block, qml_function
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class WifiSpeedtest(unittest.TestCase):
    def test_cancelled_process_cannot_publish_over_replacement(self):
        source = (SHELL / "modules/wifi/WifiService.qml").read_text()
        measure = qml_function(source, "measure")
        stop = qml_function(source, "stopSpeedtest")
        finish = qml_function(source, "finishSpeedtest")
        factory = qml_block(source, "Component {\n    id: speedtestFactory")

        with tempfile.TemporaryDirectory(prefix="shell-wifi-speedtest-") as tmp:
            root = Path(tmp)
            counter = root / "requests"
            backend = root / "wifi.sh"
            code = '''import fcntl, json, os, signal, sys, time
signal.signal(signal.SIGTERM, signal.SIG_IGN)
with open(sys.argv[1], "a+") as f:
 fcntl.flock(f, fcntl.LOCK_EX); f.seek(0); n=int(f.read() or "0")+1; f.seek(0); f.truncate(); f.write(str(n)); f.flush(); fcntl.flock(f, fcntl.LOCK_UN)
time.sleep(0.25 if n == 1 else 0.04)
print(json.dumps({"ok": True, "down": n}))
'''
            backend.write_text("exec python3 -c " + shlex.quote(code) + " " + shlex.quote(str(counter)) + "\n")
            (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property string script: ''' + json.dumps(str(backend)) + '''
  property bool popupOpen: true
  property bool speedtestBusy: false
  property var speedtest: null
  property string speedtestError: ""
  property var activeSpeedtest: null
  function parse(text) { return JSON.parse(text); }
  QtObject { id: speedtestTimeout; property bool running: false; function restart() { running = true; } function stop() { running = false; } }
''' + measure + stop + finish + factory + '''
  Timer { interval: 10; running: true; onTriggered: root.measure() }
  Timer { interval: 150; running: true; onTriggered: { root.stopSpeedtest(); root.measure(); } }
  Timer { interval: 750; running: true; onTriggered: {
    console.warn("WIFI_SPEEDTEST_RESULT:" + JSON.stringify({
      result: root.speedtest, error: root.speedtestError,
      busy: root.speedtestBusy, active: root.activeSpeedtest !== null
    }));
    Qt.quit();
  } }
}
''')
            output = run_quickshell(root, timeout=4)
            results = [line.split("WIFI_SPEEDTEST_RESULT:", 1)[1]
                       for line in output.splitlines() if "WIFI_SPEEDTEST_RESULT:" in line]
            self.assertEqual(len(results), 1, output)
            self.assertEqual(json.loads(results[0]), {
                "result": {"ok": True, "down": 2}, "error": "",
                "busy": False, "active": False,
            }, output)
