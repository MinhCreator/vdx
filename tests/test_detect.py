"""Hardware detection on fake trees: the right traits, and quirks only on their machine."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from installer import detect
from tests import fakesys


class Detect(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def test_empty_tree(self):
        hw = detect.hardware(self.root)
        self.assertEqual(hw["gpus"], [])
        self.assertEqual(hw["battery"], "")
        self.assertEqual(detect.traits(hw), {"gpu": [], "hybrid": False, "laptop": False, "asus": False, "quirks": []})

    def test_tuf(self):
        fakesys.tuf(self.root)
        hw = detect.hardware(self.root)
        t = detect.traits(hw)
        self.assertEqual(t["gpu"], ["intel", "nvidia"])
        self.assertTrue(t["hybrid"] and t["laptop"] and t["asus"])
        self.assertEqual(t["quirks"], ["asus-fx516pm-headset-mic"])
        self.assertEqual(hw["battery"], "BAT0")
        self.assertTrue(hw["charge_limit"] and hw["platform_profile"])
        self.assertEqual(hw["gpus"][0]["driver"], "i915")
        self.assertEqual([m["name"] for m in hw["monitors"]], ["eDP-1"])
        self.assertTrue(hw["monitors"][0]["internal"])
        self.assertFalse(hw["dgpu_off"])

    def test_dgpu_switched_off(self):
        fakesys.tuf(self.root)
        fakesys.put(self.root, "sys/devices/platform/asus-nb-wmi/dgpu_disable", "1")
        self.assertTrue(detect.hardware(self.root)["dgpu_off"])

    def test_amd_desktop(self):
        fakesys.amd_desktop(self.root)
        hw = detect.hardware(self.root)
        t = detect.traits(hw)
        self.assertEqual(hw["cpu"], "amd")
        self.assertEqual(t["gpu"], ["amd"])
        self.assertFalse(t["laptop"], "a mouse's battery is not a laptop's")
        self.assertEqual(hw["battery"], "")
        self.assertEqual(t["quirks"], [])
        self.assertEqual({m["name"] for m in hw["monitors"]}, {"DP-1", "HDMI-A-1"})

    def test_quirk_needs_the_board(self):
        fakesys.tuf(self.root)
        fakesys.put(self.root, "sys/class/dmi/id/board_name", "FX506HM")
        self.assertEqual(detect.traits(detect.hardware(self.root))["quirks"], [])

    def test_quirk_needs_the_codec_at_hwC0D0(self):
        fakesys.tuf(self.root)
        (self.root / "proc/asound/card0/codec#0").unlink()
        fakesys.put(self.root, "proc/asound/card1/codec#0", "Codec: Realtek ALC294")
        self.assertEqual(detect.traits(detect.hardware(self.root))["quirks"], [])

    def test_arch_derivatives_count_as_arch(self):
        for text, arch in (('ID=arch\n', True), ('ID=endeavouros\nID_LIKE=arch\n', True),
                           ('ID="cachyos"\nID_LIKE="arch"\n', True), ('ID=ubuntu\nID_LIKE=debian\n', False), ('', False)):
            with self.subTest(text=text):
                fakesys.put(self.root, "etc/os-release", text)
                self.assertEqual(detect.environment(self.root)["arch"], arch)


if __name__ == "__main__":
    unittest.main()
