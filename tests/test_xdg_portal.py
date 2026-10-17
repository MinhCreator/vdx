"""The file chooser portal's wiring agrees with itself: the bus names of the backend
and of its .portal file, the lowercase name xdg-desktop-portal reads its routing from,
and the packages' files the links put in place."""

from __future__ import annotations

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
        for iface in ("FileChooser", "OpenURI"):
            self.assertIn(f"org.freedesktop.impl.portal.{iface}", portal)
            self.assertIn("Interfaces=", portal)

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


if __name__ == "__main__":
    unittest.main()
