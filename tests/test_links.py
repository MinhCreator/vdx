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
        # the portal's routing (xdg-portal) is the shell's too
        own = (str(TGT / "quickshell"), str(TGT / "hypr"), str(TGT / "xdg-desktop-portal"),
               str(HOME / ".local/share/xdg-desktop-portal"), str(HOME / ".local/share/applications/shellfiles.desktop"))
        self.assertTrue(all(str(t).startswith(own) for t in left), left)
        self.assertNotIn(HOME / ".zshenv", left)


if __name__ == "__main__":
    unittest.main()
