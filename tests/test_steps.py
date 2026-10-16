"""setup: the plan only looks, a failed step stops and is found again, backups never lose a file."""

from __future__ import annotations

import argparse
import io
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from installer import model, setup, steps


class Fake(steps.Step):
    """A step with a switch: pending until it has run."""

    def __init__(self, name, fail=False):
        self.name = self.title = name
        self.done, self.fail, self.runs = False, fail, 0

    def pending(self, ctx):
        return [] if self.done else [f"do {self.name}"]

    def run(self, ctx):
        self.runs += 1
        if self.fail:
            raise subprocess.CalledProcessError(1, ["false"])
        self.done = True


class Setup(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.state = Path(self.tmp.name)
        self.patches = [mock.patch.object(setup, "STATE", self.state),
                        mock.patch.object(setup, "preflight", return_value=True),
                        mock.patch.object(setup, "cmd_verify", return_value=0),
                        mock.patch.object(steps, "context", return_value=steps.Ctx(None, {}, set()))]
        for p in self.patches:
            p.start()

    def tearDown(self):
        for p in self.patches:
            p.stop()
        self.tmp.cleanup()

    def run_setup(self, fakes, **kw):
        args = argparse.Namespace(yes=True, dry_run=False, **kw)
        with mock.patch.object(steps, "STEPS", fakes), mock.patch("sys.stdout", new=io.StringIO()):
            return setup.cmd_setup(args)

    def test_dry_run_changes_nothing(self):
        a = Fake("a")
        args = argparse.Namespace(yes=True, dry_run=True)
        with mock.patch.object(steps, "STEPS", [a]), mock.patch("sys.stdout", new=io.StringIO()):
            self.assertEqual(setup.cmd_setup(args), 0)
        self.assertEqual(a.runs, 0)

    def test_a_failure_stops_and_the_next_run_skips_what_is_done(self):
        a, b, c = Fake("a"), Fake("b", fail=True), Fake("c")
        self.assertEqual(self.run_setup([a, b, c]), 1)
        self.assertEqual((a.runs, b.runs, c.runs), (1, 1, 0))
        journal = json.loads((self.state / "setup.json").read_text())
        self.assertEqual(journal["steps"]["a"], "done")
        self.assertTrue(journal["steps"]["b"].startswith("failed"))
        b.fail = False
        self.assertEqual(self.run_setup([a, b, c]), 0)
        self.assertEqual((a.runs, b.runs, c.runs), (1, 2, 1))
        self.assertIn("finished", json.loads((self.state / "setup.json").read_text()))

    def test_a_step_with_work_only_after_an_earlier_one_still_runs(self):
        a = Fake("a")
        b = Fake("b")
        b.pending = lambda ctx: [] if b.done or not a.done else ["do b"]    # chsh once zsh is in
        self.assertEqual(self.run_setup([a, b]), 0)
        self.assertEqual((a.runs, b.runs), (1, 1))

    def test_nothing_pending_runs_nothing(self):
        a = Fake("a")
        a.done = True
        self.assertEqual(self.run_setup([a]), 0)
        self.assertEqual(a.runs, 0)

    def test_the_log_has_no_colours(self):
        a = Fake("a")
        self.run_setup([a])
        log = next(self.state.glob("setup-*.log")).read_text()
        self.assertIn("do a", log)
        self.assertNotIn("\x1b[", log)


class Backups(unittest.TestCase):
    def test_a_real_file_is_moved_never_overwritten(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp) / "home"
            backup = Path(tmp) / "backup"
            target = home / ".config" / "kitty" / "kitty.conf"
            with mock.patch.object(model, "HOME", home), mock.patch("sys.stdout", new=io.StringIO()):
                for text in ("first", "second"):
                    target.parent.mkdir(parents=True, exist_ok=True)
                    target.write_text(text)
                    model.resolve_conflict(target, backup)
            self.assertFalse(target.exists())
            kept = sorted(p.read_text() for p in (backup / ".config" / "kitty").iterdir())
            self.assertEqual(kept, ["first", "second"])

    def test_a_link_is_just_removed(self):
        with tempfile.TemporaryDirectory() as tmp:
            link = Path(tmp) / "x"
            link.symlink_to("/nonexistent")
            model.resolve_conflict(link, Path(tmp) / "backup")
            self.assertFalse(link.is_symlink())
            self.assertFalse((Path(tmp) / "backup").exists())


class Services(unittest.TestCase):
    CTX = steps.Ctx(None, {"laptop": {"services": ["tlp.service"], "user_services": [], "masks": []}}, {"laptop"})

    def test_a_running_rival_is_named(self):
        with mock.patch.object(steps, "systemd_running", return_value=True), \
             mock.patch.object(steps, "active", side_effect=lambda u: u == "power-profiles-daemon.service"), \
             mock.patch.object(steps, "enabled", return_value="enabled"):
            lines = steps.Services().by_hand(self.CTX)
        self.assertEqual(len(lines), 1)
        self.assertIn("power-profiles-daemon.service is running and fights tlp.service", lines[0])

    def test_without_systemd_nothing_is_enabled_only_listed(self):
        with mock.patch.object(steps, "systemd_running", return_value=False):
            self.assertEqual(steps.Services().pending(self.CTX), [])
            lines = steps.Services().by_hand(self.CTX)
        self.assertEqual(len(lines), 1)
        self.assertIn("systemd is not running", lines[0])
        self.assertIn("tlp.service", lines[0])


if __name__ == "__main__":
    unittest.main()
