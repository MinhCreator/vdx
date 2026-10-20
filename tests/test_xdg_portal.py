"""The file chooser portal's wiring agrees with itself: the bus names of the backend
and of its .portal file, the lowercase name xdg-desktop-portal reads its routing from,
and the packages' files the links put in place; the filters an app asks for, as the
picker matches them."""

from __future__ import annotations

import importlib.util
import re
import tomllib
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SHELL = ROOT / "packages/quickshell/shell"
PKG = ROOT / "packages/xdg-portal"


class Portal(unittest.TestCase):
    def test_the_backend_owns_the_name_its_portal_file_names(self):
        code = (SHELL / "scripts/files_portal.py").read_text()
        name = re.search(r'^BUS = "([^"]+)"', code, re.M).group(1)
        portal = (PKG / "shellfiles.portal").read_text()
        self.assertIn(f"DBusName={name}", portal)
        self.assertIn("Interfaces=org.freedesktop.impl.portal.FileChooser;", portal)
        # there is no impl OpenURI in xdg-desktop-portal: claiming one would route nothing
        self.assertNotIn("OpenURI", portal)

    def test_the_routing_file_is_lowercase_as_xdg_desktop_portal_reads_it(self):
        names = {p.name for p in PKG.iterdir()}
        self.assertIn("hyprland-portals.conf", names)
        self.assertFalse(any(n != n.lower() and n.endswith("-portals.conf") for n in names), names)
        routing = (PKG / "hyprland-portals.conf").read_text()
        self.assertIn("org.freedesktop.impl.portal.FileChooser=shellfiles", routing)

    def test_the_package_maps_its_files_to_their_targets(self):
        manifest = tomllib.loads((PKG / "package.toml").read_text())
        for source in manifest["files"]:
            self.assertTrue((PKG / source).is_file(), source)

    def test_the_launcher_entry_runs_the_shell_ipc(self):
        entry = (PKG / "shellfiles.desktop").read_text()
        self.assertIn("Exec=qs -c shell ipc call files open", entry)
        self.assertIn("MimeType=inode/directory;", entry)


def portal():
    spec = importlib.util.spec_from_file_location("files_portal", SHELL / "scripts/files_portal.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


@unittest.skipUnless(importlib.util.find_spec("gi"), "python-gobject is not installed")
class Filters(unittest.TestCase):
    def test_a_mime_type_becomes_the_globs_of_its_extensions(self):
        f = portal().filters_of([("PDF", [(1, "application/pdf")]), ("Web page", [(1, "text/html"), (0, "*.mht")])])
        self.assertEqual(f[0]["patterns"], ["*.pdf"])
        self.assertEqual(set(f[1]["patterns"]), {"*.html", "*.htm", "*.mht"})

    def test_a_major_type_and_a_glob_stay_as_they_are(self):
        self.assertEqual(portal().patterns_of([(1, "image/*"), (0, "*.txt")]), ["image/*", "*.txt"])

    def test_an_unknown_type_adds_no_pattern(self):
        self.assertEqual(portal().patterns_of([(1, "application/x-made-up")]), [])

    def test_the_current_filter_comes_first(self):
        f = portal().filters_of([("All", [(0, "*")]), ("PDF", [(1, "application/pdf")])], ("PDF", [(1, "application/pdf")]))
        self.assertEqual([x["name"] for x in f], ["PDF", "All"])


if __name__ == "__main__":
    unittest.main()
