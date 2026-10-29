"""music.sh: a station parks the music — the whole player as it stood (queue with tags, track,
second) in one file, the only record of it — and --unpark brings it back at the same track and
second; other music dropped onto the queue drops it. --listen reports every MPD event, also the
ones that come while it reads the state. mpc is a stand-in that logs its calls."""

from __future__ import annotations

import json
import os
import select
import shutil
import subprocess
import tempfile
import time
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/scripts/music.sh"

# the queue: two tracks, the second playing at 1:05; the station is "http://r/love"
FAKE_MPC = r"""#!/bin/bash
echo "mpc $*" >> "$FAKE_LOG"
case "$*" in
  "-q add") cat >> "$FAKE_ADDED" ;;
  "current -f %file%") echo "$FAKE_FILE" ;;
  current\ -f\ *) printf '%s\tSong\tBand\tAlbum\t2024-05-01\t\n' "$FAKE_FILE" ;;
  playlist\ -f\ *) printf '1\ta.mp3\tFirst\tOne\tA1\t2023\t2:00\n2\tdir/b.flac\t\tTwo\t\t\t3:20\n' ;;
  "status") ;;
  status\ *) if [[ "$*" == *songpos*currenttime* && "$*" != *state* ]]; then printf '2\t1:05\n'
             else printf '%s\t2\t2\t1:05\t3:20\toff\toff\toff\n' "$(cat "$FAKE_STATE")"; fi ;;
  # three events on one connection, the state changed before each
  "idleloop player playlist options") for s in paused stopped playing; do sleep 0.2; echo "$s" > "$FAKE_STATE"; echo player; done
                                      exec sleep 30 ;;
esac
exit 0
"""


class MusicScript(unittest.TestCase):
    def setUp(self):
        self.tmp = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.tmp, ignore_errors=True)
        home = self.tmp / "home"
        (home / ".config/scripts/radio").mkdir(parents=True)
        (home / ".config/scripts/radio/stations.json").write_text(
            json.dumps({"love": {"name": "Love Radio", "url": "http://r/love"}}))
        (self.tmp / "bin").mkdir()
        mpc = self.tmp / "bin/mpc"
        mpc.write_text(FAKE_MPC)
        mpc.chmod(0o755)
        self.log = self.tmp / "log"
        self.added = self.tmp / "added"
        self.state = self.tmp / "state"
        self.parked = self.state / "music-parked.json"

    def env(self, playing="dir/b.flac", state="playing"):
        (self.tmp / "mpd-state").write_text(state)
        return {**os.environ, "HOME": str(self.tmp / "home"), "XDG_STATE_HOME": str(self.state),
                "PATH": f"{self.tmp / 'bin'}:{os.environ['PATH']}", "FAKE_LOG": str(self.log),
                "FAKE_ADDED": str(self.added), "FAKE_FILE": playing, "FAKE_STATE": str(self.tmp / "mpd-state")}

    def run_script(self, *args, **kw):
        out = subprocess.run(["bash", str(SCRIPT), *args], env=self.env(**kw), capture_output=True,
                             text=True, check=True).stdout
        return json.loads(out.strip().splitlines()[-1])

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    # ---- parking ----
    def test_station_parks_the_whole_player(self):
        self.assertTrue(self.run_script("--radio", "love")["ok"])
        parked = json.loads(self.parked.read_text())
        self.assertEqual(parked, {
            "pos": 2, "file": "dir/b.flac", "title": "b", "artist": "Two", "album": "", "year": "",
            "duration": 200, "elapsed": 65,
            "queue": [{"pos": 1, "file": "a.mp3", "artist": "One", "title": "First"},
                      {"pos": 2, "file": "dir/b.flac", "artist": "Two", "title": "b"}]})
        self.assertIn("mpc -q add http://r/love", self.calls())

    def test_status_and_parked_queue_read_the_record(self):
        self.run_script("--radio", "love")
        status = self.run_script("--status", playing="http://r/love")
        self.assertEqual(status["source"], "radio")
        self.assertEqual(status["parked"]["title"], "b")
        self.assertEqual(status["parked"]["length"], 2)
        self.assertNotIn("queue", status["parked"])
        self.assertEqual(self.run_script("--parked-queue"),
                         [{"pos": 1, "artist": "One", "title": "First"}, {"pos": 2, "artist": "Two", "title": "b"}])

    def test_unpark_restores_queue_track_and_second(self):
        self.run_script("--radio", "love")
        self.assertTrue(self.run_script("--unpark")["ok"])
        self.assertEqual(self.added.read_text(), "a.mp3\ndir/b.flac\n")
        self.assertIn("mpc -q play 2", self.calls())
        self.assertIn("mpc -q seek 65", self.calls())
        self.assertFalse(self.parked.exists())
        self.assertFalse(self.run_script("--status")["parked"])

    def test_a_station_playing_is_not_parked_again(self):
        self.run_script("--radio", "love")
        before = self.parked.read_text()
        self.run_script("--radio", "love", playing="http://r/love")
        self.assertEqual(self.parked.read_text(), before)

    def test_nothing_playing_parks_nothing(self):
        self.run_script("--radio", "love", playing="")
        self.assertFalse(self.parked.exists())
        self.assertEqual(self.run_script("--parked-queue"), [])

    def test_other_music_drops_the_parked_one(self):
        self.run_script("--radio", "love")
        music = self.tmp / "music"
        music.mkdir()
        (music / "x.mp3").write_text("")
        self.run_script("--files-play", str(music), playing="http://r/love")
        self.assertFalse(self.parked.exists())

    def test_music_over_a_station_holds_the_station(self):
        music = self.tmp / "music"
        music.mkdir()
        (music / "x.mp3").write_text("")
        self.run_script("--files-play", str(music), playing="http://r/love")
        self.assertEqual((self.state / "radio-held").read_text(), "love\n")
        status = self.run_script("--status", playing="http://r/love")
        self.assertEqual(status["heldRadio"], "love")
        self.assertTrue(self.run_script("--release-radio")["ok"])
        self.assertFalse((self.state / "radio-held").exists())

    def test_music_over_music_holds_no_station_and_a_station_clears_the_hold(self):
        music = self.tmp / "music"
        music.mkdir()
        (music / "x.mp3").write_text("")
        self.run_script("--files-play", str(music))
        self.assertFalse((self.state / "radio-held").exists())
        self.run_script("--files-play", str(music), playing="http://r/love")
        self.run_script("--radio", "love")
        self.assertFalse((self.state / "radio-held").exists())

    def test_on_brings_the_parked_music_back(self):
        self.run_script("--radio", "love")
        self.assertTrue(self.run_script("--on", playing="http://r/love")["ok"])
        self.assertIn("mpc -q play 2", self.calls())
        self.assertFalse(self.parked.exists())

    def test_unpark_with_nothing_parked_is_an_error(self):
        self.assertFalse(self.run_script("--unpark")["ok"])

    # ---- listening ----
    def test_listen_reports_every_event(self):
        proc = subprocess.Popen(["bash", str(SCRIPT), "--listen"], env=self.env(), stdout=subprocess.PIPE, text=True)
        self.addCleanup(proc.stdout.close)
        self.addCleanup(proc.wait)
        self.addCleanup(proc.kill)
        states, deadline = [], time.time() + 5
        while len(states) < 4 and time.time() < deadline:
            if select.select([proc.stdout], [], [], 0.1)[0]:
                states.append(json.loads(proc.stdout.readline())["state"])
        self.assertEqual(states, ["playing", "paused", "stopped", "playing"])


if __name__ == "__main__":
    unittest.main()
