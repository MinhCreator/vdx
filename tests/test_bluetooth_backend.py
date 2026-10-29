"""Keep Bluetooth scan replies tied to the bluetoothctl result."""
from __future__ import annotations

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "packages/quickshell/shell/scripts/bluetooth.sh"


class BluetoothScanBackend(unittest.TestCase):
    def run_scan(self, reply: str) -> dict:
        with tempfile.TemporaryDirectory() as tmp:
            fake = Path(tmp) / "bluetoothctl"
            fake.write_text("#!/bin/sh\nprintf '%s\\n' \"$SCAN_REPLY\"\n")
            fake.chmod(0o755)
            env = os.environ | {
                "PATH": tmp + os.pathsep + os.environ["PATH"],
                "SCAN_REPLY": reply,
            }
            result = subprocess.run(
                ["bash", str(SCRIPT), "--scan"], capture_output=True, text=True,
                env=env, check=True,
            )
            return json.loads(result.stdout)

    def test_scan_start_reply_is_success(self):
        self.assertEqual(self.run_scan("Discovery started"), {"ok": True})

    def test_scan_rejection_is_reported(self):
        reply = "Failed to start discovery: org.bluez.Error.InProgress"
        self.assertEqual(self.run_scan(reply), {"ok": False, "error": reply})


if __name__ == "__main__":
    unittest.main()
