"""The shell's option files migrate before it starts: every value kept, the old
fixes applied once, a broken or newer file left alone, the owner's real files
(when this machine has them) loading with nothing lost."""

from __future__ import annotations

import importlib.util
import json
import os
import shutil
import tempfile
import unittest
from pathlib import Path
from unittest import mock

SCRIPT = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/scripts/settings_migrate.py"
spec = importlib.util.spec_from_file_location("settings_migrate", SCRIPT)
sm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sm)


class Migrate(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp())
        self.addCleanup(shutil.rmtree, self.dir)

    def write(self, name, data):
        (self.dir / name).write_text(json.dumps(data) if not isinstance(data, str) else data)

    def read(self, name):
        return json.loads((self.dir / name).read_text())

    def run_it(self):
        with mock.patch("builtins.print"):
            sm.main(["settings_migrate.py", str(self.dir)])

    def test_stamps_version_and_keeps_values(self):
        self.write("settings.json", {"font": "Iosevka", "textSize": 14})
        self.run_it()
        self.assertEqual(self.read("settings.json"), {"font": "Iosevka", "textSize": 14, "version": sm.VERSION})
        self.assertTrue((self.dir / "settings.json.bak").exists())

    def test_title_length_zero_becomes_icon(self):
        self.write("modules.json", {"values": {"music": {"titleLength": 0, "show": "both"},
                                               "radio": {"titleLength": 45}}})
        self.run_it()
        v = self.read("modules.json")["values"]
        self.assertEqual(v["yandex"], {"titleLength": 60, "show": "icon"})
        self.assertEqual(v["radio"], {"titleLength": 45})

    def test_layout_ids_renamed_and_roles_kept(self):
        self.write("layout.json", {"hidden": ["claude"], "screens": {
            "main": {"zones": {"left": ["plugins", "clock"], "right": ["ai", "claude"]},
                     "island": {"hub": ["claude"]}, "bars": [{"id": "b", "modules": ["plugins"]}]},
            "eDP-1": {"zones": {}}}})
        self.run_it()
        d = self.read("layout.json")
        self.assertEqual(d["hidden"], ["ai"])
        self.assertEqual(list(d["screens"]), ["main"])
        m = d["screens"]["main"]
        self.assertEqual(m["zones"], {"left": ["shell", "clock"], "right": ["ai"]})
        self.assertEqual(m["island"]["hub"], ["ai"])
        self.assertEqual(m["bars"][0]["modules"], ["shell"])

    def test_current_file_untouched(self):
        self.write("settings.json", {"version": sm.VERSION, "font": "x"})
        before = (self.dir / "settings.json").read_text()
        self.run_it()
        self.assertEqual((self.dir / "settings.json").read_text(), before)
        self.assertFalse((self.dir / "settings.json.bak").exists())

    def test_newer_file_keeps_its_version(self):
        self.write("settings.json", {"version": sm.VERSION + 5})
        self.run_it()
        self.assertEqual(self.read("settings.json")["version"], sm.VERSION + 5)

    def test_broken_and_missing_files_left_alone(self):
        self.write("settings.json", "{not json")
        self.write("modules.json", "[1, 2]")
        self.run_it()
        self.assertEqual((self.dir / "settings.json").read_text(), "{not json")
        self.assertEqual((self.dir / "modules.json").read_text(), "[1, 2]")
        self.assertFalse((self.dir / "layout.json").exists())

    def test_bookmarks_become_the_sidebar_and_frames_go(self):
        self.write("modules.json", {"values": {"files": {"bookmarks": [{"name": "src", "path": "/home/u/src"}],
                                                         "frames": True, "view": "list"}}})
        self.run_it()
        self.assertEqual(self.read("modules.json")["values"]["files"],
                         {"sidebar": [{"path": "/home/u/src", "name": "src", "kind": "folder", "hidden": False}],
                          "view": "list"})

    def test_the_files_key_hints_option_goes(self):
        self.write("modules.json", {"version": 3, "values": {"files": {"hints": False, "view": "grid"}}})
        self.run_it()
        self.assertEqual(self.read("modules.json")["values"]["files"], {"view": "grid"})

    def test_an_existing_sidebar_is_kept(self):
        kept = [{"path": "trash:", "name": "Trash", "kind": "trash", "hidden": True}]
        self.write("modules.json", {"values": {"files": {"bookmarks": [{"name": "x", "path": "/x"}], "sidebar": kept}}})
        self.run_it()
        self.assertEqual(self.read("modules.json")["values"]["files"]["sidebar"], kept)

    def test_music_options_become_yandex(self):
        self.write("modules.json", {"values": {"music": {"show": "title"}, "radio": {"titleLength": 45}}})
        self.run_it()
        v = self.read("modules.json")["values"]
        self.assertEqual(v, {"yandex": {"show": "title"}, "radio": {"titleLength": 45}})

    def test_twice_is_once(self):
        self.write("modules.json", {"values": {"music": {"titleLength": 0}}})
        self.run_it()
        first = self.read("modules.json")
        self.run_it()
        self.assertEqual(self.read("modules.json"), first)

    def test_state_dir_follows_quickshell(self):
        with mock.patch.dict(os.environ, {"XDG_CONFIG_HOME": "/c", "XDG_STATE_HOME": "/s"}):
            self.assertEqual(sm.state_dir(), Path("/s/quickshell/by-shell/") /
                             __import__("hashlib").md5(b"/c/quickshell/shell/shell.qml").hexdigest())

    def test_owners_files_keep_every_value(self):
        real = sm.state_dir()
        if not (real / "settings.json").exists():
            self.skipTest("no shell state on this machine")
        for n in sm.FILES:
            if (real / n).exists():
                shutil.copy(real / n, self.dir / n)
        before = {n: json.loads((self.dir / n).read_text()) for n in sm.FILES if (self.dir / n).exists()}
        self.run_it()
        for n, old in before.items():
            new = self.read(n)
            if n == "settings.json":
                for k, val in old.items():
                    if k != "version":
                        self.assertEqual(new[k], val, k)
            if n == "modules.json":
                # the music options were renamed to yandex (version 3)
                self.assertEqual(set(new["values"]), {"yandex" if k == "music" else k for k in old["values"]})
            self.assertGreaterEqual(new["version"], sm.VERSION)


if __name__ == "__main__":
    unittest.main()
