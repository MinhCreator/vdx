"""update, doctor, uninstall, rollback: nothing is lost, nothing but ours is touched."""

from __future__ import annotations

import argparse
import io
import os
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from installer import hypr, maintain, steps
from installer.paths import ROOT


class Restore(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name) / "home"
        self.backup = Path(self.tmp.name) / "backup" / "2026-10-16T10-00-00"
        self.home.mkdir()

    def tearDown(self):
        self.tmp.cleanup()

    def put(self, rel, text):
        f = self.backup / rel
        f.parent.mkdir(parents=True, exist_ok=True)
        f.write_text(text)

    def test_files_come_back_and_the_folder_goes(self):
        self.put(".config/kitty/kitty.conf", "mine")
        done, kept = maintain.restore(self.backup, self.home)
        self.assertEqual((self.home / ".config/kitty/kitty.conf").read_text(), "mine")
        self.assertEqual(kept, [])
        self.assertFalse(self.backup.exists())

    def test_our_link_gives_way_but_a_real_file_does_not(self):
        self.put(".config/a.conf", "old a")
        self.put(".config/b.conf", "old b")
        (self.home / ".config").mkdir()
        (self.home / ".config/a.conf").symlink_to(ROOT / "README.md")   # a link of ours
        (self.home / ".config/b.conf").write_text("new b")                    # someone's real file
        done, kept = maintain.restore(self.backup, self.home)
        self.assertEqual((self.home / ".config/a.conf").read_text(), "old a")
        self.assertEqual((self.home / ".config/b.conf").read_text(), "new b")
        self.assertEqual([p.name for p in kept], ["b.conf"])
        self.assertTrue((self.backup / ".config/b.conf").exists(), "a file that can't go back stays backed up")

    def test_a_link_elsewhere_is_never_replaced(self):
        self.put("x", "old")
        (self.home / "x").symlink_to("/etc/hostname")
        _, kept = maintain.restore(self.backup, self.home)
        self.assertEqual(len(kept), 1)
        self.assertTrue((self.home / "x").is_symlink())

    def test_second_copies_stay_in_the_backup(self):
        self.put("x", "first")
        self.put("x.~1", "second")
        done, kept = maintain.restore(self.backup, self.home)
        self.assertEqual((self.home / "x").read_text(), "first")
        self.assertEqual([p.name for p in kept], ["x.~1"])


class Generated(unittest.TestCase):
    def test_only_marked_files_are_removed_or_reported(self):
        with tempfile.TemporaryDirectory() as tmp:
            d = Path(tmp)
            (d / "gpu.lua").write_text(f"-- {hypr.MARK}\nold\n")
            (d / "mine.lua").write_text("-- by hand\n")
            profile = {"hypr": {"gpu_env": "none"}}
            self.assertEqual(hypr.out_of_step(profile, d), ["gpu.lua"])
            self.assertEqual([p.name for p in hypr.remove_generated(d)], ["gpu.lua"])
            self.assertTrue((d / "mine.lua").exists())


class Doctor(unittest.TestCase):
    def doctor(self, plan, health):
        with mock.patch.object(steps, "context", return_value=steps.Ctx(None, {}, set())), \
             mock.patch.object(steps, "plan", return_value=plan), \
             mock.patch.object(maintain, "health", return_value=health), \
             mock.patch("sys.stdout", new=io.StringIO()) as out:
            return maintain.cmd_doctor(argparse.Namespace()), out.getvalue()

    def test_healthy(self):
        self.assertEqual(self.doctor([(steps.Links(), [], [])], [])[0], 0)

    def test_pending_work_and_errors_fail_warnings_do_not(self):
        code, text = self.doctor([(steps.Links(), ["link 1 file(s)"], [])], [])
        self.assertEqual(code, 1)
        self.assertIn("link 1 file(s)", text)
        self.assertEqual(self.doctor([], [("warn", "hardware changed", "machine detect")])[0], 0)
        self.assertEqual(self.doctor([], [("err", "mihomo lacks", "setcap")])[0], 1)

    def test_missing_capabilities_are_named(self):
        ctx = steps.Ctx(None, {"vpn": {k: [] for k in ("services", "user_services")}}, {"vpn"}, {"hardware": {}})
        with mock.patch.object(maintain, "getcap", return_value=""), \
             mock.patch.object(maintain.Path, "exists", return_value=True), \
             mock.patch.object(maintain.detect, "hardware", return_value={}), \
             mock.patch.object(maintain.detect, "environment", return_value={"hyprland": ""}), \
             mock.patch.object(maintain, "BACKUPS", Path("/nonexistent")):
            found = maintain.health(ctx)
        self.assertTrue(any("mihomo lacks" in what for _, what, _ in found))


class NoSystemd(unittest.TestCase):
    def test_enabled_units_are_not_expected_to_run_without_systemd(self):
        cat = {"net": {"services": ["NetworkManager.service"], "user_services": ["wireplumber.service"]}}
        ctx = steps.Ctx(None, cat, {"net"}, {"hardware": {}})
        with mock.patch.object(steps, "systemd_running", return_value=False), \
             mock.patch.object(steps, "enabled", return_value="enabled"), \
             mock.patch.object(steps, "active", return_value=False), \
             mock.patch.object(maintain.detect, "hardware", return_value={}), \
             mock.patch.object(maintain.detect, "environment", return_value={"hyprland": ""}), \
             mock.patch.object(maintain, "BACKUPS", Path("/nonexistent")):
            self.assertEqual(maintain.health(ctx), [])


class Update(unittest.TestCase):
    def test_setup_runs_in_a_new_process_with_the_same_flags(self):
        def git(*cmd):
            out = {"rev-parse": "origin/main\n", "log": ""}.get(cmd[0], "")
            return subprocess.CompletedProcess(cmd, 0, out, "")
        with mock.patch.object(maintain, "git", side_effect=git), \
             mock.patch.object(maintain.os, "execv") as execv, mock.patch("sys.stdout", new=io.StringIO()):
            maintain.cmd_update(argparse.Namespace(dry_run=True, yes=False))
        argv = execv.call_args[0][1]
        self.assertEqual(argv[-2:], ["setup", "--dry-run"])

    def test_noconfirm_reaches_setup(self):
        def git(*cmd):
            return subprocess.CompletedProcess(cmd, 0, "origin/main\n" if cmd[0] == "rev-parse" else "", "")
        with mock.patch.object(maintain, "git", side_effect=git), \
             mock.patch.object(maintain.os, "execv") as execv, mock.patch("sys.stdout", new=io.StringIO()):
            maintain.cmd_update(argparse.Namespace(dry_run=False, yes=True, noconfirm=True))
        self.assertEqual(execv.call_args[0][1][-3:], ["setup", "-y", "--noconfirm"])

    def test_a_failed_pull_stops_before_setup(self):
        def git(*cmd):
            if cmd[0] == "pull":
                return subprocess.CompletedProcess(cmd, 1, "", "fatal: Not possible to fast-forward")
            return subprocess.CompletedProcess(cmd, 0, "origin/main\n" if cmd[0] == "rev-parse" else "", "")
        with mock.patch.object(maintain, "git", side_effect=git), \
             mock.patch.object(maintain.os, "execv") as execv, mock.patch("sys.stdout", new=io.StringIO()):
            self.assertEqual(maintain.cmd_update(argparse.Namespace(dry_run=False, yes=False)), 1)
        execv.assert_not_called()


class SyncSubmodules(unittest.TestCase):
    """A pull moves a submodule's recorded commit; its checkout follows only when that loses nothing."""

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        base = Path(self.tmp.name)
        self.env = {"GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t", "GIT_COMMITTER_NAME": "t",
                    "GIT_COMMITTER_EMAIL": "t@t", "GIT_CONFIG_COUNT": "1", "GIT_CONFIG_KEY_0": "protocol.file.allow",
                    "GIT_CONFIG_VALUE_0": "always", "PATH": os.environ["PATH"]}
        self.sub_origin, self.root = base / "sub.git", base / "root"
        self.g(base, "init", "-q", "-b", "main", str(self.sub_origin))
        self.commit(self.sub_origin, "a")
        self.g(base, "init", "-q", "-b", "main", str(self.root))
        self.g(self.root, "submodule", "add", "-q", str(self.sub_origin), "mod")
        self.g(self.root, "commit", "-qm", "add mod")
        self.old = self.git_out(self.root, "rev-parse", "HEAD")
        self.commit(self.sub_origin, "b")                      # upstream moves on
        self.g(self.root / "mod", "pull", "-q")
        self.g(self.root, "commit", "-qam", "bump mod")        # the pull's result: a new recorded commit
        self.want = self.git_out(self.root, "rev-parse", "HEAD:mod")
        self.g(self.root / "mod", "checkout", "-q", "HEAD~1")  # ... and the checkout is still behind

    def tearDown(self):
        self.tmp.cleanup()

    def g(self, cwd, *args):
        subprocess.run(["git", *args], cwd=cwd, env=self.env, check=True, capture_output=True)

    def git_out(self, cwd, *args):
        return subprocess.run(["git", *args], cwd=cwd, env=self.env, check=True, capture_output=True, text=True).stdout.strip()

    def commit(self, repo, name):
        (repo / name).write_text(name)
        self.g(repo, "add", name)
        self.g(repo, "commit", "-qm", name)

    def sync(self):
        def git(*cmd):
            return subprocess.run(["git", "-C", str(self.root), *cmd], env=self.env, capture_output=True, text=True)
        with mock.patch.object(maintain, "ROOT", self.root), mock.patch.object(maintain, "git", side_effect=git), \
             mock.patch.dict("os.environ", self.env), mock.patch("sys.stdout", new=io.StringIO()):
            maintain.sync_submodules(self.old, ["mod"])

    def head(self):
        return self.git_out(self.root / "mod", "rev-parse", "HEAD")

    def test_a_clean_checkout_behind_follows(self):
        self.sync()
        self.assertEqual(self.head(), self.want)

    def test_local_changes_stay(self):
        (self.root / "mod" / "a").write_text("edited")
        before = self.head()
        self.sync()
        self.assertEqual(self.head(), before)
        self.assertEqual((self.root / "mod" / "a").read_text(), "edited")

    def test_commits_of_its_own_stay(self):
        self.commit(self.root / "mod", "mine")
        before = self.head()
        self.sync()
        self.assertEqual(self.head(), before)


if __name__ == "__main__":
    unittest.main()
