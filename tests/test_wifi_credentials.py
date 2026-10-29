"""Exercise Wi-Fi completion handlers without running network commands."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class WifiCredentials(unittest.TestCase):
    def complete(self, payload):
        source = (SHELL / "modules/wifi/WifiService.qml").read_text()
        for process, busy in (("connectProc", "connectingSsid"),
                              ("hiddenProc", "hiddenBusy"),
                              ("hotspotActionProc", "hotspotBusy")):
            with self.subTest(process=process, payload=payload), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                handler = qml_block(source[source.index("id: " + process):], "onStreamFinished:")
                (root / "shell.qml").write_text('''import QtQuick
import Quickshell
Scope {
  id: root
  property string text: ''' + json.dumps(payload) + '''
  property string connectingSsid: "test-network"
  property string connectStatus: ""
  property string connectError: ""
  property string password: "fixture-password"
  property bool hiddenBusy: true
  property string hiddenError: ""
  property bool hotspotBusy: true
  property string hotspotError: ""
  property bool clearedBeforeIdle: false
  onConnectingSsidChanged: if (!connectingSsid) observe()
  onHiddenBusyChanged: if (!hiddenBusy) observe()
  onHotspotBusyChanged: if (!hotspotBusy) observe()
  function observe() { clearedBeforeIdle = Object.keys(''' + process + '''.environment).length === 0; }
  function parse(text) { return JSON.parse(text); }
  function refresh() {}
  function refreshSaved() {}
  function refreshStatus() {}
  function refreshNetworks() {}
  function refreshHotspot() {}
  QtObject { id: connectClear; function restart() {} }
  QtObject { id: ''' + process + '''; property var environment: ({WIFI_PASS: "fixture-password"}) }
  function complete() ''' + handler.split(":", 1)[1] + '''
  Timer { interval: 10; running: true; onTriggered: {
    complete();
    console.warn("CREDENTIAL_RESULT:" + JSON.stringify({
      cleared: Object.keys(''' + process + '''.environment).length === 0,
      beforeIdle: clearedBeforeIdle,
      idle: !''' + busy + '''
    }));
    Qt.quit();
  } }
}
''')
                output = run_quickshell(root)
                results = [line.split("CREDENTIAL_RESULT:", 1)[1]
                           for line in output.splitlines() if "CREDENTIAL_RESULT:" in line]
                self.assertEqual(len(results), 1, output)
                self.assertEqual(json.loads(results[0]),
                                 {"cleared": True, "beforeIdle": True, "idle": True})

    def test_success_clears_credentials_before_idle(self):
        self.complete('{"ok":true}')

    def test_failure_clears_credentials_before_idle(self):
        self.complete('{"ok":false,"error":"fixture failure"}')
