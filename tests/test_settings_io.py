"""About › Settings: an export imports back equal, a bad bundle changes nothing,
reset leaves defaults and keeps what was there."""

from __future__ import annotations

import importlib.util
import json
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/scripts"
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location("settings_io", SCRIPTS / "settings_io.py")
io = importlib.util.module_from_spec(spec)
spec.loader.exec_module(io)

FILES = {
    "settings.json": {"version": 1, "barStyle": "island", "looks": {"island": {"barGap": 8}}},
    "modules.json": {"version": 1, "values": {"music": {"show": "icon"}}},
    "layout.json": {"version": 1, "zones": {"left": ["workspaces"]}},
}
WINDOWS = {"windows.json": {"gapsIn": 4}, "window-mode": "scrolling"}


class SettingsIO(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.dir)
        self.wdir = self.dir / "dotfiles"
        self.wdir.mkdir()
        for n, d in FILES.items():
            (self.dir / n).write_text(json.dumps(d))
        (self.wdir / "windows.json").write_text(json.dumps(WINDOWS["windows.json"]))
        (self.wdir / "window-mode").write_text("scrolling\n")

    def run_io(self, *args):
        return io.main(["settings_io.py", *args, "--dir", str(self.dir), "--windows-dir", str(self.wdir)])

    def read(self, name):
        if name == "window-mode":
            return (self.wdir / name).read_text().strip()
        return json.loads(((self.wdir if name in WINDOWS else self.dir) / name).read_text())

    def test_round_trip(self):
        out = self.dir / "out.json"
        self.assertEqual(self.run_io("export", str(out)), 0)
        for n in FILES:
            (self.dir / n).write_text(json.dumps({"version": 1}))
        (self.wdir / "windows.json").write_text("{}")
        (self.wdir / "window-mode").write_text("tiling\n")
        self.assertEqual(self.run_io("import", str(out)), 0)
        for n, d in WINDOWS.items():
            self.assertEqual(self.read(n), d)
        for n, d in FILES.items():
            # the import migrates them to the current version (the music module's options stay under "music")
            want = dict(d, version=io.sm.VERSION)
            self.assertEqual(self.read(n), want)
            self.assertEqual(json.loads((self.dir / (n + ".bak")).read_text()), {"version": 1})

    def test_import_migrates(self):
        out = self.dir / "old.json"
        out.write_text(json.dumps({"kind": io.KIND, "files": {
            "modules.json": {"values": {"radio": {"titleLength": 0}}}}}))
        self.assertEqual(self.run_io("import", str(out)), 0)
        self.assertEqual(self.read("modules.json")["values"]["music"], {"show": "icon", "titleLength": 60})
        self.assertEqual(self.read("settings.json"), FILES["settings.json"])   # not in the bundle: kept

    def test_bad_bundle_changes_nothing(self):
        for text in ("not json", json.dumps([1]), json.dumps({"kind": "other", "files": {}}),
                     json.dumps({"kind": io.KIND, "files": {"x.json": {}}})):
            bad = self.dir / "bad.json"
            bad.write_text(text)
            self.assertEqual(self.run_io("import", str(bad)), 1)
            for n, d in FILES.items():
                self.assertEqual(self.read(n), d)
        self.assertEqual(self.run_io("import", str(self.dir / "missing.json")), 1)

    def test_bad_mode_dropped(self):
        out = self.dir / "mode.json"
        out.write_text(json.dumps({"kind": io.KIND, "files": {"window-mode": "rm -rf", "windows.json": {"gapsIn": 2}}}))
        self.assertEqual(self.run_io("import", str(out)), 0)
        self.assertEqual(self.read("window-mode"), "scrolling")
        self.assertEqual(self.read("windows.json"), {"gapsIn": 2})

    def test_reset(self):
        self.assertEqual(self.run_io("reset"), 0)
        self.assertEqual(self.read("windows.json"), {})
        self.assertEqual(self.read("window-mode"), "tiling")
        for n, d in FILES.items():
            self.assertEqual(self.read(n), {"version": io.sm.VERSION})
            self.assertEqual(json.loads((self.dir / (n + ".bak")).read_text()), d)
        saved = self.read("settings-before-reset.json")
        self.assertEqual(saved["files"], {**FILES, **WINDOWS})


if __name__ == "__main__":
    unittest.main()
