"""Links follow the selection; nothing else on the disk is looked at differently."""

from __future__ import annotations

import unittest
from unittest import mock

from installer import components, model
from installer.paths import HOME, TGT


def targets(on: set[str] | None) -> set:
    if on is None:
        return {t for _, t, _ in model.build_entries(every=True)}
    with mock.patch.object(components, "selected", return_value=on):
        return {t for _, t, _ in model.build_entries()}


class Links(unittest.TestCase):
    def setUp(self):
        self.cat = components.load()
        self.all = targets(None)

    def test_everything_on_is_every_link(self):
        self.assertEqual(targets(set(self.cat)), self.all)

    def test_vpn_off_takes_its_files_only(self):
        gone = self.all - targets(set(self.cat) - {"vpn"})
        self.assertIn(TGT / "zsh" / "functions" / "vpn", gone)
        self.assertNotIn(TGT / "zsh" / "functions" / "radio", gone)
        owned = ("mihomo", "mihomo-tui", "scripts/vpn", "zsh/functions/vpn")
        self.assertTrue(all(any(str(t).startswith(str(TGT / p)) for p in owned) for t in gone), gone)

    def test_only_quickshell(self):
        on = components.closure({"quickshell"}, self.cat)
        left = targets(on)
        self.assertTrue(left)
        self.assertTrue(all(str(t).startswith((str(TGT / "quickshell"), str(TGT / "hypr"))) for t in left), left)
        self.assertNotIn(HOME / ".zshenv", left)


if __name__ == "__main__":
    unittest.main()
