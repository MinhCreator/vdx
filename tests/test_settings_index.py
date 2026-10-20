"""The Shell Manager's search: the index is current, every target is a page the
Shell Manager opens, and the common tasks (05 › Journeys) are found by a word."""

from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/scripts/settings_index.py"
spec = importlib.util.spec_from_file_location("settings_index", SCRIPT)
si = importlib.util.module_from_spec(spec)
spec.loader.exec_module(si)

TABS = {"themes", "fonts", "cursor", "appearance", "animations", "bar", "modules", "windows", "lockscreen", "notifications",
        "network", "bluetooth", "displays", "apps", "about"}

# a word typed -> where the task is done
JOURNEYS = {
    "wallpaper": "appearance:wallpaper",
    "toast": "notifications",
    "show bar": "bar:monitor",
    "clock format": "lockscreen",
    "animations": "animations:general",
    "seconds": "modules:clock",
    "theme": "themes",
    "text size": "fonts",
    "accent": "appearance:accent",
    "gap": "windows:look",
    "search field": "modules:clipboard",
    "pause": "modules:audio",
    "dot colour": "notifications",
    "width": "apps:launcher",
    "reset everything": "about:settings",
    "refresh rate": "displays:monitor",
}


def search(index, q):
    q = q.lower()
    return [e for e in index if q in e["label"].lower() or q in e["hint"].lower()]


class Index(unittest.TestCase):
    index = si.build()

    def test_current(self):
        self.assertEqual(si.main(["settings_index.py", "--check"]), 0, "run scripts/settings_index.py")

    def test_targets(self):
        for e in self.index:
            self.assertIn(e["target"].split(":")[0], TABS, e)
            self.assertTrue(e["label"].strip(), e)

    def test_journeys(self):
        for q, target in JOURNEYS.items():
            self.assertIn(target, [e["target"] for e in search(self.index, q)], q)


if __name__ == "__main__":
    unittest.main()
