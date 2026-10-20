"""Components: selection rules, file owners, catalog mistakes, and the real catalog."""

from __future__ import annotations

import unittest

from installer import components


def catalog(**entries) -> dict:
    """A catalog as load() returns it."""
    base = {k: [] for k in components.LISTS}
    return {n: {**base, "default": True, "about": n, **c} for n, c in entries.items()}


HW_TUF = {"vendor": "ASUSTeK COMPUTER INC.", "board": "FX516PM", "chassis": "laptop", "battery": "BAT0",
          "gpus": [{"vendor": "intel"}, {"vendor": "nvidia"}],
          "codecs": [{"card": 0, "index": 0, "name": "Realtek ALC294"}]}
HW_AMD = {"vendor": "MSI", "board": "B550", "chassis": "desktop", "battery": "", "gpus": [{"vendor": "amd"}], "codecs": []}

CAT = catalog(
    core={"group": "core"},
    hypr={"group": "desktop"},
    quickshell={"group": "desktop", "requires": ["hypr"], "suggests": ["mako"]},
    mako={"group": "desktop", "default": False},
    mpd={"group": "music", "default": False},
    radio={"group": "music", "default": False, "requires": ["mpd"]},
    nvidia={"group": "hardware", "auto": ["gpu:nvidia"]},
    asus={"group": "hardware", "auto": ["asus", "hybrid"]},
    amd={"group": "hardware", "auto": ["gpu:amd"]},
)


class Selection(unittest.TestCase):
    def test_closure_adds_core_and_requires(self):
        self.assertEqual(components.closure({"radio"}, CAT), {"core", "radio", "mpd"})
        self.assertEqual(components.closure({"nope"}, CAT), {"core"})

    def test_never_chosen_is_everything_detected(self):
        self.assertEqual(components.everything(CAT, HW_TUF),
                         {"core", "hypr", "quickshell", "mako", "mpd", "radio", "nvidia", "asus"})
        self.assertEqual(components.everything(CAT, HW_AMD) & {"nvidia", "asus", "amd"}, {"amd"})

    def test_defaults_follow_suggests_and_detection(self):
        self.assertEqual(components.defaults(CAT, HW_AMD), {"core", "hypr", "quickshell", "mako", "amd"})

    def test_auto_terms_all_hold(self):
        self.assertTrue(components.detected(CAT["asus"], HW_TUF))
        self.assertFalse(components.detected(CAT["asus"], {**HW_TUF, "gpus": [{"vendor": "intel"}]}))

    def test_selected_uses_the_saved_list(self):
        profile = {"hardware": HW_TUF, "components": {"selected": ["radio"]}}
        self.assertEqual(components.selected(profile, CAT), {"core", "radio", "mpd"})
        self.assertIsNone(components.saved({"hardware": HW_TUF}))

    def test_a_split_component_follows_its_parent(self):
        cat = catalog(core={"group": "core"}, shell={"group": "desktop"},
                      backups={"group": "desktop", "requires": ["shell"], "split_from": "shell"})
        before = {"components": {"selected": ["shell"]}}          # saved before the split
        self.assertIn("backups", components.selected(before, cat))
        took_off = {"components": {"selected": ["shell"], "off": ["backups"]}}
        self.assertNotIn("backups", components.selected(took_off, cat))
        self.assertNotIn("backups", components.selected({"components": {"selected": []}}, cat))

    def test_record_keeps_a_split_component_off(self):
        cat = catalog(core={"group": "core"}, shell={"group": "desktop"},
                      backups={"group": "desktop", "requires": ["shell"], "split_from": "shell"})
        self.assertEqual(components.record({"core", "shell"}, cat), {"selected": ["shell"], "off": ["backups"]})
        self.assertEqual(components.record({"core", "shell", "backups"}, cat), {"selected": ["shell", "backups"]})
        self.assertEqual(components.record({"core"}, cat), {"selected": []})

    def test_required_by(self):
        self.assertEqual(components.required_by("mpd", {"mpd", "radio", "hypr"}, CAT), ["radio"])


class Owners(unittest.TestCase):
    TABLE = components.claims(catalog(
        zsh={"group": "terminal", "links": ["zsh", "home/.zshenv"]},
        vpn={"group": "network", "links": ["zsh/functions/vpn", "scripts/vpn"]},
        scripts={"group": "terminal", "links": ["scripts/battery.sh"]},
    ))

    def test_longest_path_wins(self):
        self.assertEqual(components.owner("zsh/functions/vpn", self.TABLE), "vpn")
        self.assertEqual(components.owner("zsh/functions/radio", self.TABLE), "zsh")
        self.assertEqual(components.owner("zsh/.zshrc", self.TABLE), "zsh")

    def test_whole_names_only(self):
        self.assertIsNone(components.owner("zsh-extra/x", self.TABLE))
        self.assertIsNone(components.owner("scripts/battery.sh.bak", self.TABLE))
        self.assertEqual(components.owner("scripts/vpn/manager.py", self.TABLE), "vpn")

    def test_home(self):
        self.assertEqual(components.owner("home/.zshenv", self.TABLE), "zsh")
        self.assertIsNone(components.owner("home/.profile", self.TABLE))

    def test_the_yandex_backend_belongs_to_its_component(self):
        # the shell's own backends stay with quickshell; yandex.py (the module and the app) with yandex-music
        table = components.claims(components.load())
        self.assertEqual(components.owner("quickshell/shell/scripts/yandex.py", table), "yandex-music")
        self.assertEqual(components.owner("quickshell/shell/scripts/music.sh", table), "quickshell")
        self.assertEqual(components.owner("quickshell/shell/scripts/backend.py", table), "quickshell")


class Problems(unittest.TestCase):
    def test_a_clean_catalog(self):
        self.assertEqual(components.problems(CAT), [])

    def test_mistakes_are_named(self):
        bad = catalog(
            a={"group": "desktop", "requires": ["b"], "pakman": ["x"]},
            b={"group": "desktop", "requires": ["a"]},
            c={"group": "games", "requires": ["ghost"]},
            d={"group": "hardware"},
            e={"group": "desktop", "auto": ["laptop"], "pacman": ["x"], "aur": ["x"]},
            f={"group": "hardware", "auto": ["quirk:nope", "moon"]},
            g={"group": "desktop", "links": ["a/b"]},
            h={"group": "desktop", "links": ["a/b"]},
            i={"group": "desktop", "split_from": "h"},
        )
        text = "\n".join(components.problems(bad))
        for needle in ("[a]: unknown field 'pakman'", "[a] requires itself", "[c]: group 'games'",
                       "requires 'ghost': no such component", "[d]: hardware needs auto",
                       "[e]: auto is for hardware only", "[e]: pacman and aur both list x",
                       "auto 'quirk:nope': no such quirk", "auto 'moon': unknown term",
                       "links 'a/b' is in both [g] and [h]",
                       "[i]: split_from 'h' must be a component it requires"):
            self.assertIn(needle, text)


class RealCatalog(unittest.TestCase):
    """components.toml as it is in the repo."""

    def setUp(self):
        self.cat = components.load()

    def test_no_problems(self):
        self.assertEqual(components.problems(self.cat), [])

    def test_this_laptop_never_chosen_gets_its_hardware(self):
        on = components.everything(self.cat, HW_TUF)
        self.assertTrue({"gpu-intel", "gpu-nvidia", "laptop", "asus", "asus-fx516pm-headset-mic"} <= on)
        self.assertNotIn("gpu-amd", on)

    def test_a_stranger_gets_no_personal_bits(self):
        on = components.defaults(self.cat, HW_AMD)
        for personal in ("vpn", "yandex-music", "radio", "private", "telegram", "asus", "laptop",
                         "gpu-nvidia", "asus-fx516pm-headset-mic"):
            self.assertNotIn(personal, on)
        for wanted in ("hypr", "quickshell", "kitty", "zsh", "nvim", "gpu-amd"):
            self.assertIn(wanted, on)

    def test_quickshell_alone_brings_hyprland(self):
        self.assertIn("hypr", components.closure({"quickshell"}, self.cat))


if __name__ == "__main__":
    unittest.main()
