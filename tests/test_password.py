"""The password backend: it answers passwd's prompts on a pty and reports what
passwd said. A fake `passwd` stands in for the real one."""

from __future__ import annotations

import json
import os
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/scripts/password.py"

FAKE = """#!/bin/sh
printf 'Changing password for me.\\nCurrent password: '
read cur
[ "$cur" = "old" ] || {{ printf '\\npasswd: Authentication failure\\n'; exit 10; }}
printf '\\nNew password: '
read new
printf '\\nRetype new password: '
read again
[ "$new" = "$again" ] || {{ printf '\\nSorry, passwords do not match.\\n'; exit 10; }}
{extra}
printf '\\npasswd: password updated successfully\\n'
"""


def change(current, new, extra=""):
    with tempfile.TemporaryDirectory() as tmp:
        fake = Path(tmp) / "passwd"
        fake.write_text(FAKE.format(extra=extra))
        fake.chmod(fake.stat().st_mode | stat.S_IXUSR)
        env = dict(os.environ, PATH=tmp + ":" + os.environ["PATH"])
        proc = subprocess.run([sys.executable, str(SCRIPT), "change"], input=json.dumps({"current": current, "new": new}),
                              capture_output=True, text=True, env=env, timeout=30)
    return proc.returncode, json.loads(proc.stdout)


class PasswordTest(unittest.TestCase):
    def test_changes(self):
        self.assertEqual(change("old", "brand-new"), (0, {"ok": True}))

    def test_wrong_current(self):
        code, reply = change("nope", "brand-new")
        self.assertEqual(code, 1)
        self.assertEqual(reply["error"], "Wrong current password")

    def test_weak_new(self):
        code, reply = change("old", "abc", "printf '\\nBAD PASSWORD: it is too short\\n'; exit 10")
        self.assertEqual(code, 1)
        self.assertEqual(reply["error"], "The new password is too short")

    def test_empty(self):
        self.assertEqual(change("", "x")[1]["error"], "Both passwords are needed")

    def test_never_echoes_a_password(self):
        code, reply = change("old", "brand-new", "printf 'x brand-new x\\n'; exit 10")
        self.assertNotIn("brand-new", reply["error"])


if __name__ == "__main__":
    unittest.main()
