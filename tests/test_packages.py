"""packages.py: the download's progress is read from the root script's copy
(pacman's own download-* dirs are the alpm user's), and the script carries a
watcher that ends with its shell."""

from __future__ import annotations

import importlib.util
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPTS = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/scripts"
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location("packages", SCRIPTS / "packages.py")
pk = importlib.util.module_from_spec(spec)
spec.loader.exec_module(pk)


class Progress(unittest.TestCase):
    def test_counts_finished_and_downloading_once(self):
        with tempfile.TemporaryDirectory() as d:
            cache, watch = Path(d) / "pkg", Path(d) / "watch"
            cache.mkdir()
            (cache / "foo-1.0-1-x86_64.pkg.tar.zst").write_bytes(b"x" * 100)
            # bar is mid-download; foo shows in both for a moment: counted once
            watch.write_text("40 bar-2.0-1-x86_64.pkg.tar.zst.part\n100 foo-1.0-1-x86_64.pkg.tar.zst\n")
            pk.CACHE, pk.WATCH = cache, watch
            r = pk.progress(["foo=1.0-1", "bar=2.0-1", "baz=3.0-1"])
        self.assertEqual(r, {"ok": True, "bytes": 140})

    def test_download_script_has_the_watcher(self):
        plan = pk.plan_download(["foo"])
        self.assertTrue(plan["script"].startswith("( while kill -0 $$"))
        self.assertTrue(plan["script"].endswith("pacman -Syw --noconfirm -- foo"))
        self.assertEqual(plan["steps"][0]["command"], "pacman -Syw --noconfirm -- foo")


if __name__ == "__main__":
    unittest.main()
