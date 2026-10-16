"""System files: placeholders, and only the selected components' files."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path
from unittest import mock

from installer import components, model


class Render(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.file = Path(self.tmp.name) / "power.conf"

    def tearDown(self):
        self.tmp.cleanup()

    def test_battery_name(self):
        self.file.write_text("z /sys/class/power_supply/@BATTERY@/x 0664 root wheel -\n")
        self.assertEqual(model.render(self.file, {"battery": "BAT1"}),
                         b"z /sys/class/power_supply/BAT1/x 0664 root wheel -\n")

    def test_no_value_is_an_error_not_an_empty_path(self):
        self.file.write_text("@BATTERY@\n")
        for hw in ({}, {"battery": ""}, {"battery": True}):
            with self.assertRaises(ValueError):
                model.render(self.file, hw)

    def test_plain_files_are_untouched(self):
        self.file.write_bytes(b"user@host # email@example.com\n")
        self.assertEqual(model.render(self.file, {}), b"user@host # email@example.com\n")


class Selection(unittest.TestCase):
    def files(self, on: set[str]) -> set[str]:
        with mock.patch.object(components, "selected", return_value=on):
            return {str(f.relative_to(model.SYSTEM)) for f in model.system_files()}

    def test_everything_is_every_file(self):
        self.assertEqual(self.files(set(components.load())),
                         {str(f.relative_to(model.SYSTEM)) for f in model.system_files(every=True)})

    def test_a_desktop_gets_no_laptop_files(self):
        cat = components.load()
        got = self.files(set(cat) - {"laptop", "nvidia-laptop", "asus-fx516pm-headset-mic", "vpn", "ollama", "airpods"})
        self.assertEqual(got, {"etc/polkit-1/rules.d/50-pkexec-keep.rules"})


if __name__ == "__main__":
    unittest.main()
