"""The display backend: a monitor moves only where it overlaps nothing, and an
old display.json (scales only) still restores."""

from __future__ import annotations

import contextlib
import importlib.util
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPTS = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/scripts"
sys.path.insert(0, str(SCRIPTS))   # display.py imports backend.py from its folder
SCRIPT = SCRIPTS / "display.py"
spec = importlib.util.spec_from_file_location("display", SCRIPT)
display = importlib.util.module_from_spec(spec)
spec.loader.exec_module(display)


def mon(name, x, y, width=1920, height=1080, scale=1.0):
    return {"name": name, "x": x, "y": y, "width": width, "height": height,
            "scale": scale, "refreshRate": 60.0, "disabled": False}


def run(fn, *args):
    """Call a command, return what it printed and its exit code."""
    buf = io.StringIO()
    code = 0
    with contextlib.redirect_stdout(buf):
        try:
            fn(*args)
        except SystemExit as e:
            code = e.code
    return json.loads(buf.getvalue()), code


class Position(unittest.TestCase):
    def setUp(self):
        # a 1920-wide laptop at scale 1.2 (1600 logical px) and a 1920 monitor to its right
        self.monitors = [mon("eDP-1", 0, 0, scale=1.2), mon("HDMI-A-2", 1600, 0)]
        self.applied = []
        self.tmp = tempfile.TemporaryDirectory()
        self.state = Path(self.tmp.name) / "display.json"
        patches = [
            mock.patch.object(display, "monitors", side_effect=lambda: self.monitors),
            mock.patch.object(display, "apply", side_effect=lambda m, scale=None, pos=None: self.applied.append((m["name"], pos))),
            mock.patch.object(display, "STATE", self.state),
        ]
        for p in patches:
            p.start()
            self.addCleanup(p.stop)
        self.addCleanup(self.tmp.cleanup)

    def test_overlap_is_refused_and_nothing_applied(self):
        out, code = run(display.cmd_position, "HDMI-A-2", "1000", "0")
        self.assertEqual((out["ok"], code), (False, 1))
        self.assertIn("eDP-1", out["error"])
        self.assertEqual(self.applied, [])

    def test_touching_edges_are_allowed_and_saved(self):
        out, code = run(display.cmd_position, "HDMI-A-2", "1600", "0")
        self.assertEqual((out["ok"], code), (True, 0))
        self.assertEqual(self.applied, [("HDMI-A-2", (1600, 0))])
        self.assertEqual(json.loads(self.state.read_text())["positions"], {"HDMI-A-2": [1600, 0]})

    def test_logical_size_follows_scale(self):
        self.assertEqual(display.logical(self.monitors[0]), (0, 0, 1600, 900))

    def test_old_state_without_positions_loads(self):
        self.state.write_text(json.dumps({"scales": {"eDP-1": 1.25}}))
        self.assertEqual(display.saved(), {"scales": {"eDP-1": 1.25}, "positions": {}})


if __name__ == "__main__":
    unittest.main()
