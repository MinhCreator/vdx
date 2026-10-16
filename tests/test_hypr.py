"""This machine's Hyprland files: what the profile writes, and what is never touched."""

from __future__ import annotations

import shutil
import subprocess
import tempfile
import unittest
from pathlib import Path

from installer import hypr

TUF = {
    "hypr": {
        "gpu_env": "nvidia", "layouts": "us,ru", "layout_options": "grp:caps_toggle",
        "monitors": [{"output": "eDP-1", "mode": "1920x1080@144.00", "position": "0x0", "scale": 1.2},
                     {"output": "HDMI-A-1", "mode": "1920x1080@144.00", "position": "1600x0", "scale": 1}],
        "workspaces": {"HDMI-A-1": "1-8", "eDP-1": "9-10"},
    },
}
HYBRID = {"gpus": [{"vendor": "intel"}, {"vendor": "nvidia"}]}
NVIDIA_ONLY = {"gpus": [{"vendor": "nvidia"}]}


class Render(unittest.TestCase):
    def test_tuf(self):
        files = hypr.render(TUF, HYBRID)
        self.assertIn('hl.env("GBM_BACKEND", "nvidia-drm")', files["gpu"])
        self.assertIn('kb_layout = "us,ru",\n\t\tkb_options = "grp:caps_toggle",', files["input"])
        m = files["monitors"]
        self.assertIn('\tposition = "1600x0",\n\tscale = 1,\n', m)
        self.assertIn('\tscale = 1.2,\n', m)
        rules = [line for line in m.splitlines() if line.startswith("hl.workspace_rule")]
        self.assertEqual(len(rules), 10)
        self.assertEqual(rules[0], 'hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })')
        self.assertEqual(rules[8], 'hl.workspace_rule({ workspace = "9", monitor = "eDP-1", default = true })')
        self.assertEqual(rules[9], 'hl.workspace_rule({ workspace = "10", monitor = "eDP-1" })')

    def test_nothing_set_is_nothing_written(self):
        self.assertEqual(hypr.render({}, {"gpus": [{"vendor": "amd"}]}), {"gpu": None, "input": None, "monitors": None})

    def test_nvidia_env_by_default_only_without_an_igpu(self):
        self.assertIsNotNone(hypr.render({}, NVIDIA_ONLY)["gpu"])
        self.assertIsNone(hypr.render({}, HYBRID)["gpu"])
        self.assertIsNone(hypr.render({"hypr": {"gpu_env": "none"}}, NVIDIA_ONLY)["gpu"])

    def test_strings_are_escaped(self):
        text = hypr.render({"hypr": {"layouts": 'us"); os.exit("'}}, {})["input"]
        self.assertIn(r'kb_layout = "us\"); os.exit(\"",', text)

    @unittest.skipUnless(shutil.which("luac"), "luac is not installed")
    def test_lua_parses(self):
        with tempfile.TemporaryDirectory() as tmp:
            for name, text in hypr.render(TUF, HYBRID).items():
                f = Path(tmp) / f"{name}.lua"
                f.write_text(text)
                r = subprocess.run(["luac", "-p", str(f)], capture_output=True, text=True)
                self.assertEqual(r.returncode, 0, r.stderr)


class Session(unittest.TestCase):
    """The running Hyprland keeps the env it started with (the Brave video bug)."""
    NVIDIA = dict(hypr.NVIDIA_ENV)
    CLEAN = {k: None for k, _ in hypr.NVIDIA_ENV}

    def stale(self, profile, env):
        from unittest import mock
        with mock.patch.object(hypr.machine, "hardware", return_value=HYBRID):
            return hypr.stale_session(profile, env)

    def test_old_nvidia_env_after_switching_to_none(self):
        found = self.stale({"hypr": {"gpu_env": "none"}}, self.NVIDIA)
        self.assertIn("LIBVA_DRIVER_NAME=nvidia", found)
        self.assertEqual(len(found), len(hypr.NVIDIA_ENV))

    def test_in_step(self):
        self.assertEqual(self.stale({"hypr": {"gpu_env": "none"}}, self.CLEAN), [])
        self.assertEqual(self.stale({"hypr": {"gpu_env": "nvidia"}}, self.NVIDIA), [])

    def test_the_other_way_round(self):
        self.assertIn("LIBVA_DRIVER_NAME=(unset)", self.stale({"hypr": {"gpu_env": "nvidia"}}, self.CLEAN))

    def test_no_session_no_verdict(self):
        from unittest import mock
        with mock.patch.dict(hypr.os.environ, {}, clear=True):
            self.assertIsNone(hypr.session_env())
            self.assertEqual(hypr.stale_session({"hypr": {"gpu_env": "none"}}), [])


class Problems(unittest.TestCase):
    def test_ranges(self):
        self.assertEqual(hypr.workspace_numbers("1-3, 7"), [1, 2, 3, 7])
        with self.assertRaises(ValueError):
            hypr.workspace_numbers("1-x")

    def test_mistakes(self):
        bad = {"hypr": {"gpu_env": "amd", "monitors": [{"mode": "x"}, {"output": "DP-1", "scale": "big"}],
                        "workspaces": {"HDMI-A-9": "1", "DP-1": "a"}}}
        text = "\n".join(hypr.problems(bad))
        for needle in ("gpu_env 'amd'", "monitors[0]: needs an output", "monitors[1]: scale",
                       "'HDMI-A-9' is not in monitors", "bad range 'a'"):
            self.assertIn(needle, text)
        self.assertEqual(hypr.problems(TUF), [])


class Apply(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.dir = Path(self.tmp.name)

    def tearDown(self):
        self.tmp.cleanup()

    def run_apply(self, profile):
        from unittest import mock
        with mock.patch.object(hypr.machine, "hardware", return_value=HYBRID):
            return hypr.apply(profile, self.dir, quiet=True)

    def test_writes_once_then_removes_what_is_dropped(self):
        self.assertEqual(self.run_apply(TUF), 3)
        self.assertEqual(self.run_apply(TUF), 0)
        self.assertEqual(self.run_apply({"hypr": {**TUF["hypr"], "layouts": ""}}), 1)
        self.assertFalse((self.dir / "input.lua").exists())

    def test_a_hand_written_file_is_never_touched(self):
        (self.dir / "monitors.lua").write_text("-- mine\n")
        self.run_apply(TUF)
        self.run_apply({})
        self.assertEqual((self.dir / "monitors.lua").read_text(), "-- mine\n")

    def test_a_broken_profile_writes_nothing(self):
        self.assertEqual(self.run_apply({"hypr": {"gpu_env": "amd"}}), 0)
        self.assertEqual(list(self.dir.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
