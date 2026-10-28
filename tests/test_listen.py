"""listen.sh: the watched command ends with the backend, even when the backend
is killed hard (a leaked `pactl subscribe` once made the audio server refuse
clients, and gpu-screen-recorder then found no default device)."""

from __future__ import annotations

import os
import signal
import subprocess
import time
import unittest
from pathlib import Path

LISTEN = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/scripts/listen.sh"


def alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    return True


class ListenTest(unittest.TestCase):
    def test_killed_backend_takes_its_command_along(self):
        script = f'. {LISTEN}; ok() {{ echo ok; }}; listen_to sleep 100'
        backend = subprocess.Popen(["bash", "-c", script], stdout=subprocess.DEVNULL)
        time.sleep(0.5)
        out = subprocess.run(["pgrep", "-P", str(backend.pid)], capture_output=True, text=True).stdout.split()
        self.assertTrue(out, "the watched command did not start")
        child = int(out[0])
        backend.send_signal(signal.SIGKILL)
        backend.wait()
        for _ in range(20):
            if not alive(child):
                break
            time.sleep(0.1)
        else:
            os.kill(child, signal.SIGKILL)
            self.fail("the watched command outlived its backend")


if __name__ == "__main__":
    unittest.main()
