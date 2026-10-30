"""Verify Bluetooth actions recover when their child process cannot start."""
from __future__ import annotations

import json
from pathlib import Path
import shutil
import tempfile
import unittest

from tests.check_shell_ui import qml_block
from tests.qml_runtime import SHELL, run_quickshell


@unittest.skipUnless(shutil.which("qs"), "Quickshell is not installed")
class BluetoothProcessStart(unittest.TestCase):
    def test_failed_action_starts_clear_busy_state_and_report_errors(self):
        source = (SHELL / "modules/bluetooth/BluetoothService.qml").read_text()
        fixtures = (
            ("powerProc", 'property bool toggling: true', 'root.toggling', "could not start bluetooth power request"),
            ("scanProc", 'property bool scanning: true', 'root.scanning', "could not start bluetooth scan"),
            ("adapterProc", 'property bool adapterBusy: true\n  property var adapterQueue: [["--block", "fixture"]]',
             'root.adapterBusy || root.adapterQueue.length > 0', "could not start bluetooth settings request"),
            ("deviceProc", 'property string busyMac: "fixture-device"', 'root.busyMac !== ""',
             "could not start bluetooth device request"),
        )
        for process, state, busy_expr, expected_error in fixtures:
            with self.subTest(process=process), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                process_source = source[source.index("id: " + process):]
                started_handler = "onStarted: started = true"
                running_handler = qml_block(process_source, "onRunningChanged:")
                (root / "shell.qml").write_text('''import QtQuick
import Quickshell
import Quickshell.Io
Scope {
  id: root
  property string actionError: ""
  ''' + state + '''
  function refresh() {}
  Process {
    id: proc
    property bool started: false
    command: ["/no/such/bluetooth-backend"]
    running: true
    ''' + started_handler + '''
    ''' + running_handler.replace(process, "proc") + '''
  }
  Timer { interval: 100; running: true; onTriggered: {
    console.warn("BT_START_RESULT:" + JSON.stringify({
      busy: ''' + busy_expr + ''', error: root.actionError
    }));
    Qt.quit();
  } }
}
''')
                output = run_quickshell(root)
                results = [line.split("BT_START_RESULT:", 1)[1]
                           for line in output.splitlines() if "BT_START_RESULT:" in line]
                self.assertEqual(len(results), 1, output)
                self.assertEqual(json.loads(results[0]),
                                 {"busy": False, "error": expected_error}, output)


if __name__ == "__main__":
    unittest.main()
