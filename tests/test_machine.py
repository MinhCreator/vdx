"""The profile file: what is written reads back the same."""

from __future__ import annotations

import tomllib
import unittest

from installer import machine


class Profile(unittest.TestCase):
    def test_round_trip(self):
        profile = {
            "version": 1,
            "hardware": {
                "vendor": 'Quote " and back\\slash, юникод',
                "battery": "", "charge_limit": True, "cycles": 3,
                "gpus": [{"vendor": "intel", "pci": "0000:00:02.0", "boot": True}],
                "monitors": [],
            },
            "override": {"battery": "BAT1"},
            "components": {"selected": ["hypr", "quickshell"]},
        }
        self.assertEqual(tomllib.loads(machine.dumps(profile)), profile)

    def test_overrides_win(self):
        hw = machine.hardware({"hardware": {"battery": "BAT0", "wifi": "wlo1"}, "override": {"battery": "BAT1"}})
        self.assertEqual(hw, {"battery": "BAT1", "wifi": "wlo1"})

    def test_monitors_are_no_change(self):
        old = {"cpu": "intel", "monitors": [{"name": "eDP-1"}]}
        self.assertEqual(machine.changes(old, {**old, "monitors": []}), [])
        self.assertEqual(machine.changes(old, {**old, "cpu": "amd"}), ["cpu"])


if __name__ == "__main__":
    unittest.main()
