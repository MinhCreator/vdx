"""Capture moves preserve the temporary file on failure and require replace."""
from __future__ import annotations

import errno
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest import mock

from tests.qml_runtime import SHELL


def backend():
    script = SHELL / "scripts/capture.py"
    spec = importlib.util.spec_from_file_location("capture_backend", script)
    module = importlib.util.module_from_spec(spec)
    with mock.patch.object(sys, "path", [str(script.parent), *sys.path]):
        spec.loader.exec_module(module)
    return module


class CaptureSave(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="capture-save-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.source = self.root / "temporary.png"
        self.source.write_bytes(b"new capture")
        self.target = self.root / "output.png"
        self.capture = backend()

    def test_save_creates_the_folder_and_moves_the_capture(self):
        target = self.root / "new folder" / "a 'quoted' $(name).png"
        self.assertTrue(self.capture.save(self.source, target)["ok"])
        self.assertEqual(target.read_bytes(), b"new capture")
        self.assertFalse(self.source.exists())

    def test_existing_file_requires_explicit_replace(self):
        self.target.write_bytes(b"old capture")
        result = self.capture.save(self.source, self.target)
        self.assertTrue(result["exists"])
        self.assertEqual(self.target.read_bytes(), b"old capture")
        self.assertTrue(self.source.exists())
        self.assertTrue(self.capture.save(self.source, self.target, replace=True)["ok"])
        self.assertEqual(self.target.read_bytes(), b"new capture")
        self.assertFalse(self.source.exists())

    def test_same_path_is_not_deleted(self):
        self.assertTrue(self.capture.save(self.source, self.source)["ok"])
        self.assertEqual(self.source.read_bytes(), b"new capture")

    def test_relative_paths_and_missing_sources_are_rejected(self):
        with self.assertRaises(ValueError):
            self.capture.save(self.source, "relative.png")
        with self.assertRaises(ValueError):
            self.capture.save(self.root / "missing", self.target)
        self.assertFalse(self.target.exists())

    def test_filesystem_without_links_uses_an_exclusive_copy(self):
        with mock.patch.object(self.capture.os, "link", side_effect=OSError(errno.EXDEV, "cross-device")):
            self.assertTrue(self.capture.save(self.source, self.target)["ok"])
        self.assertEqual(self.target.read_bytes(), b"new capture")
        self.assertFalse(self.source.exists())

    def test_failed_copy_removes_partial_output_and_keeps_source(self):
        def fail_copy(src, dst):
            dst.write(b"partial")
            raise OSError("disk full")
        with mock.patch.object(self.capture.os, "link", side_effect=OSError(errno.EXDEV, "cross-device")), \
             mock.patch.object(self.capture.shutil, "copyfileobj", side_effect=fail_copy), \
             self.assertRaises(OSError):
            self.capture.save(self.source, self.target)
        self.assertEqual(self.source.read_bytes(), b"new capture")
        self.assertFalse(self.target.exists())

    def test_replace_across_filesystems_keeps_old_target_if_copy_fails(self):
        self.target.write_bytes(b"old capture")
        replace = self.capture.os.replace
        def cross_device(source, target):
            if source == self.source:
                raise OSError(errno.EXDEV, "cross-device")
            replace(source, target)
        with mock.patch.object(self.capture.os, "replace", side_effect=cross_device), \
             mock.patch.object(self.capture.shutil, "copy2", side_effect=OSError("disk full")), \
             self.assertRaises(OSError):
            self.capture.save(self.source, self.target, replace=True)
        self.assertEqual(self.target.read_bytes(), b"old capture")
        self.assertEqual(self.source.read_bytes(), b"new capture")
        self.assertEqual(list(self.root.glob(".capture-*")), [])

    def test_replace_across_filesystems_succeeds(self):
        self.target.write_bytes(b"old capture")
        replace = self.capture.os.replace
        def cross_device(source, target):
            if source == self.source:
                raise OSError(errno.EXDEV, "cross-device")
            replace(source, target)
        with mock.patch.object(self.capture.os, "replace", side_effect=cross_device):
            self.assertTrue(self.capture.save(self.source, self.target, replace=True)["ok"])
        self.assertEqual(self.target.read_bytes(), b"new capture")
        self.assertFalse(self.source.exists())
        self.assertEqual(list(self.root.glob(".capture-*")), [])

    def test_cli_reports_failure_as_json(self):
        result = subprocess.run([sys.executable, str(SHELL / "scripts/capture.py"), "save", str(self.source), "relative"],
                                capture_output=True, text=True)
        self.assertEqual(result.returncode, 1)
        self.assertFalse(json.loads(result.stdout)["ok"])

    def test_clipboard_passes_the_image_through_stdin(self):
        def consume(command, stdin, **kwargs):
            self.assertEqual(command, ["wl-copy", "--type", "image/png"])
            self.assertEqual(stdin.read(), b"new capture")
            self.assertEqual(kwargs["stdout"], subprocess.DEVNULL)
            self.assertTrue(hasattr(kwargs["stderr"], "write"))
            return subprocess.CompletedProcess(command, 0, b"", b"")
        with mock.patch.object(self.capture.subprocess, "run", side_effect=consume):
            self.assertTrue(self.capture.clipboard(self.source)["ok"])
        self.assertTrue(self.source.exists())

    def test_clipboard_reports_failure_without_deleting_source(self):
        def fail(command, **kwargs):
            kwargs["stderr"].write(b"clipboard unavailable")
            return subprocess.CompletedProcess(command, 1)
        with mock.patch.object(self.capture.subprocess, "run", side_effect=fail):
            reply = self.capture.clipboard(self.source)
        self.assertFalse(reply["ok"])
        self.assertEqual(reply["error"], "clipboard unavailable")
        self.assertTrue(self.source.exists())


if __name__ == "__main__":
    unittest.main()
