"""The wizard's choices: requires stay whole, suggestions come once, the start is never a surprise."""

from __future__ import annotations

import tempfile
import tomllib
import unittest
from pathlib import Path
from unittest import mock

from installer import components, machine, wizard
from tests.test_components import CAT, HW_AMD


class Picks(unittest.TestCase):
    def test_ticking_brings_requires_and_suggestions(self):
        p = wizard.Picks(CAT, set())
        self.assertEqual(p.toggle("quickshell"), "")
        self.assertTrue({"quickshell", "hypr", "mako", "core"} <= p.on)

    def test_a_required_one_cant_be_unticked(self):
        p = wizard.Picks(CAT, {"quickshell"})
        self.assertIn("required by quickshell", p.toggle("hypr"))
        self.assertIn("hypr", p.on)
        self.assertEqual(p.toggle("quickshell"), "")
        self.assertEqual(p.toggle("hypr"), "")
        self.assertNotIn("hypr", p.on)

    def test_core_is_always_on(self):
        p = wizard.Picks(CAT, set())
        self.assertIn("always", p.toggle("core"))
        self.assertNotIn("core", p.chosen())

    def test_unticking_keeps_what_it_brought(self):
        p = wizard.Picks(CAT, set())
        p.toggle("radio")
        p.toggle("radio")
        self.assertIn("mpd", p.on)


class Keys(unittest.TestCase):
    def test_escape_is_back_not_quit(self):
        self.assertEqual(wizard.key_name("\x1b"), "left")

    def test_q_asks_once_more(self):
        q = wizard.Quit()
        self.assertEqual(q.press("quit"), "ask")
        self.assertEqual(q.press("quit"), "quit")

    def test_another_key_between_starts_over(self):
        q = wizard.Quit()
        q.press("quit")
        self.assertEqual(q.press("down"), "down")
        self.assertEqual(q.press("quit"), "ask")


class Start(unittest.TestCase):
    def answers(self, profile, managed):
        with mock.patch.object(machine, "load", return_value=profile), \
             mock.patch.object(wizard, "find_managed", return_value=managed), \
             mock.patch.object(wizard.detect, "hardware", return_value=HW_AMD):
            return wizard.start(CAT)

    def test_a_fresh_machine_gets_the_defaults(self):
        a = self.answers(None, [])
        self.assertEqual(a.picks.on, components.defaults(CAT, HW_AMD))

    def test_a_machine_set_up_before_keeps_everything_it_has(self):
        a = self.answers({"hardware": HW_AMD}, ["/home/x/.zshenv"])
        self.assertIn("radio", a.picks.on, "the owner's music must not be switched off")

    def test_saved_choices_win(self):
        a = self.answers({"hardware": HW_AMD, "components": {"selected": ["radio"]}}, ["x"])
        self.assertEqual(a.picks.chosen(), ["mpd", "radio"])


class Save(unittest.TestCase):
    def test_writes_the_profile_and_the_theme(self):
        with tempfile.TemporaryDirectory() as tmp:
            prof, theme = Path(tmp) / ".machine.toml", Path(tmp) / ".theme"
            a = wizard.Answers(picks=wizard.Picks(CAT, {"radio"}), theme="nord", layouts="us,de",
                               toggle="grp:alt_shift_toggle", hw=HW_AMD,
                               profile={"hardware": HW_AMD, "override": {"battery": "BAT1"}})
            with mock.patch.object(machine, "PROFILE", prof), mock.patch.object(wizard, "THEME_FILE", theme):
                wizard.save(a)
            p = tomllib.loads(prof.read_text())
            self.assertEqual(p["components"]["selected"], ["mpd", "radio"])
            self.assertEqual(p["hypr"], {"layouts": "us,de", "layout_options": "grp:alt_shift_toggle"})
            self.assertEqual(p["override"], {"battery": "BAT1"})
            self.assertEqual(theme.read_text(), "nord\n")

    def test_a_split_component_left_out_is_saved_off(self):
        cat = {**CAT, "backups": {**CAT["mako"], "about": "b", "default": True, "requires": ["quickshell"],
                                  "split_from": "quickshell"}}
        with tempfile.TemporaryDirectory() as tmp:
            prof = Path(tmp) / ".machine.toml"
            a = wizard.Answers(picks=wizard.Picks(cat, {"quickshell"}), theme="nord", layouts="us",
                               toggle="", hw=HW_AMD, profile={})
            with mock.patch.object(machine, "PROFILE", prof), mock.patch.object(wizard, "THEME_FILE", Path(tmp) / ".theme"):
                wizard.save(a)
            self.assertEqual(tomllib.loads(prof.read_text())["components"]["off"], ["backups"])

    def test_one_layout_needs_no_switch(self):
        with tempfile.TemporaryDirectory() as tmp:
            prof = Path(tmp) / ".machine.toml"
            a = wizard.Answers(picks=wizard.Picks(CAT, set()), theme="nord", layouts="us",
                               toggle="grp:caps_toggle", hw=HW_AMD, profile={"hypr": {"layout_options": "x"}})
            with mock.patch.object(machine, "PROFILE", prof), mock.patch.object(wizard, "THEME_FILE", Path(tmp) / "t"), \
                 mock.patch.object(wizard.detect, "hardware", return_value=HW_AMD):
                wizard.save(a)
            self.assertNotIn("layout_options", tomllib.loads(prof.read_text())["hypr"])


if __name__ == "__main__":
    unittest.main()
