"""music.sh: a station parks the music in the queue (saved playlist, place noted) and --unpark
brings it back at the same track and second. mpc is a stand-in that logs its calls."""

from __future__ import annotations

import json
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/scripts/music.sh"

FAKE_MPC = """#!/bin/bash
echo "mpc $*" >> "$FAKE_LOG"
case "$*" in
  "current -f %file%") echo "$FAKE_FILE" ;;
  playlist\\ *) printf 'a.mp3\\nb.mp3\\n' ;;
  current\\ -f\\ *) printf 'Song\\tBand\\n' ;;
  status\\ *) printf '3\\t1:05\\t3:20\\n' ;;
esac
exit 0
"""


class Park(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(lambda: __import__("shutil").rmtree(self.tmp, ignore_errors=True))
        home = self.tmp / "home"
        (home / ".config/scripts/radio").mkdir(parents=True)
        (home / ".config/scripts/radio/stations.json").write_text(
            json.dumps({"love": {"name": "Love Radio", "url": "http://r/love"}}))
        (self.tmp / "bin").mkdir()
        mpc = self.tmp / "bin/mpc"
        mpc.write_text(FAKE_MPC)
        mpc.chmod(0o755)
        self.log = self.tmp / "log"
        self.state = self.tmp / "state"

    def run_script(self, *args, playing="/music/a.mp3"):
        env = {**os.environ, "HOME": str(self.tmp / "home"), "XDG_STATE_HOME": str(self.state),
               "PATH": f"{self.tmp / 'bin'}:{os.environ['PATH']}", "FAKE_LOG": str(self.log), "FAKE_FILE": playing}
        out = subprocess.run(["bash", str(SCRIPT), *args], env=env, capture_output=True, text=True, check=True).stdout
        return json.loads(out.strip().splitlines()[-1])

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_station_parks_the_music_and_unpark_restores_it(self):
        self.assertTrue(self.run_script("--radio", "love")["ok"])
        self.assertEqual((self.state / "music-parked.queue").read_text(), "a.mp3\nb.mp3\n")
        self.assertEqual((self.state / "music-parked").read_text(), "3\t65\tSong\tBand\t200\n")
        self.assertTrue(self.run_script("--unpark")["ok"])
        self.assertIn("mpc -q add", self.calls())
        self.assertIn("mpc -q play 3", self.calls())
        self.assertIn("mpc -q seek 65", self.calls())
        self.assertFalse((self.state / "music-parked").exists())

    def test_a_station_playing_is_not_parked(self):
        self.run_script("--radio", "love", playing="http://r/love")
        self.assertFalse((self.state / "music-parked.queue").exists())
        self.assertFalse((self.state / "music-parked").exists())

    def test_unpark_with_nothing_parked_is_an_error(self):
        out = self.run_script("--unpark")
        self.assertFalse(out["ok"])


if __name__ == "__main__":
    unittest.main()
