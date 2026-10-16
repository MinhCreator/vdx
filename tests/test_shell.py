"""What the shell is told: the bar modules whose components are all off."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from installer import components, shell
from tests.test_components import catalog

CAT = catalog(
    quickshell={"group": "desktop", "modules": ["clock", "audio"]},
    ollama={"group": "ai", "modules": ["ai"]},
    claude={"group": "ai", "modules": ["ai"]},
    music={"group": "music", "modules": ["music"]},
)


class Render(unittest.TestCase):
    def off(self, on):
        return json.loads(shell.render(on, CAT))["off"]

    def test_everything_on_is_nothing_off(self):
        self.assertEqual(self.off(set(CAT)), {})

    def test_a_module_stays_while_one_of_its_components_is_on(self):
        self.assertEqual(self.off({"quickshell", "claude"}), {"music": ["music"]})
        self.assertEqual(self.off({"quickshell"}), {"ai": ["ollama", "claude"], "music": ["music"]})


class Apply(unittest.TestCase):
    def test_written_only_when_changed(self):
        with tempfile.TemporaryDirectory() as tmp, \
             mock.patch.object(components, "load", return_value=CAT), \
             mock.patch.object(components, "selected", return_value={"quickshell"}):
            f = Path(tmp) / "dotfiles" / "components.json"
            self.assertTrue(shell.apply(f))
            self.assertFalse(shell.apply(f))
            self.assertIn("music", json.loads(f.read_text())["off"])


if __name__ == "__main__":
    unittest.main()
