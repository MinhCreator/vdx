"""The file manager's backend (packages/quickshell/shell/scripts/files.py): what a
listing, a paste, a trash, a restore and a search do to a folder — run in a sandbox HOME."""

from __future__ import annotations

import json
import sys
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parent.parent / "packages/quickshell/shell/scripts/files.py"


class Files(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.home = Path(self.tmp.name)
        self.env = dict(os.environ, HOME=str(self.home), XDG_DATA_HOME=str(self.home / ".local/share"),
                        XDG_CONFIG_HOME=str(self.home / ".config"),
                        XDG_RUNTIME_DIR=str(self.home / "run"))
        (self.home / "src").mkdir()
        (self.home / "dst").mkdir()
        (self.home / "src/a.txt").write_text("a")
        (self.home / "src/.hidden").write_text("h")

    def tearDown(self):
        self.tmp.cleanup()

    def call(self, *args):
        r = subprocess.run(["python3", str(SCRIPT), *args], capture_output=True, text=True, env=self.env)
        # progress lines come first; the reply is the last one
        return json.loads(r.stdout.strip().splitlines()[-1]), r.returncode

    def path(self, name):
        return str(self.home / name)

    def test_list_tells_kinds_and_hides_nothing(self):
        o, code = self.call("list", self.path("src"))
        self.assertEqual(code, 0)
        self.assertEqual({e["name"]: e["kind"] for e in o["entries"]}, {"a.txt": "text", ".hidden": "file"})

    def test_list_counts_a_folders_items_when_asked(self):
        o, _ = self.call("list", str(self.home), "counts")
        self.assertEqual({e["name"]: e.get("count") for e in o["entries"] if e["kind"] == "dir"}, {"src": 2, "dst": 0})
        o, _ = self.call("list", str(self.home))
        self.assertNotIn("count", o["entries"][0])

    def test_recent_lists_existing_files_newest_first_once(self):
        a, b = self.path("src/a.txt"), self.path("src/.hidden")
        xbel = self.home / ".local/share/recently-used.xbel"
        xbel.parent.mkdir(parents=True)
        xbel.write_text(f'''<?xml version="1.0"?><xbel version="1.0">
<bookmark href="file://{a}" visited="2026-01-01T10:00:00Z"/>
<bookmark href="file://{b}" visited="2026-02-01T10:00:00Z"/>
<bookmark href="file://{a}" visited="2026-03-01T10:00:00Z"/>
<bookmark href="file://{self.home}/gone.txt" visited="2026-04-01T10:00:00Z"/>
<bookmark href="https://example.org/" visited="2026-05-01T10:00:00Z"/>
<bookmark href="file://{self.home}/src" visited="2026-06-01T10:00:00Z"/></xbel>''')
        o, code = self.call("recent")
        self.assertEqual(code, 0)
        self.assertEqual([e["path"] for e in o["entries"]], [a, b])
        o, _ = self.call("recent", "1")
        self.assertEqual(len(o["entries"]), 1)

    def test_entries_skips_paths_that_are_gone(self):
        o, _ = self.call("entries", self.path("src/a.txt"), self.path("nope"))
        self.assertEqual([e["name"] for e in o["entries"]], ["a.txt"])

    def test_a_name_taken_by_a_paste_gets_a_number(self):
        self.call("paste", "copy", self.path("dst"), self.path("src/a.txt"))
        o, _ = self.call("paste", "copy", self.path("dst"), self.path("src/a.txt"))
        self.assertEqual(o["done"], 1)
        self.assertTrue((self.home / "dst/a (2).txt").exists())

    def test_a_folder_can_not_go_inside_itself(self):
        (self.home / "src/sub").mkdir()
        o, _ = self.call("paste", "copy", self.path("src/sub"), self.path("src"))
        self.assertEqual(o["done"], 0)
        self.assertIn("inside itself", o["errors"][0])

    def test_move_within_the_same_folder_is_a_no_op(self):
        o, _ = self.call("paste", "move", self.path("src"), self.path("src/a.txt"))
        self.assertEqual((o["done"], o["errors"]), (0, []))
        self.assertTrue((self.home / "src/a.txt").exists())

    def test_trash_then_restore_brings_the_file_back(self):
        self.call("trash", self.path("src/a.txt"))
        self.assertFalse((self.home / "src/a.txt").exists())
        o, _ = self.call("trash-list")
        self.assertEqual([e["original"] for e in o["entries"]], [self.path("src/a.txt")])
        self.call("restore", o["entries"][0]["id"])
        self.assertEqual((self.home / "src/a.txt").read_text(), "a")

    def test_delete_removes_for_good(self):
        o, _ = self.call("delete", self.path("src/a.txt"))
        self.assertEqual(o["done"], 1)
        self.assertFalse((self.home / "src/a.txt").exists())
        self.assertEqual(self.call("trash-list")[0]["entries"], [])

    def test_rename_refuses_a_taken_name_and_bad_ones(self):
        (self.home / "src/b.txt").write_text("b")
        o, _ = self.call("rename", self.path("src/a.txt"), "b.txt")
        self.assertEqual(o["error"], "already exists")
        o, _ = self.call("rename", self.path("src/a.txt"), "../x")
        self.assertFalse(o["ok"])

    def test_search_skips_hidden_names_unless_the_query_is_dotted(self):
        names = [e["name"] for e in self.call("search", self.path("src"), "a")[0]["entries"]]
        self.assertEqual(names, ["a.txt"])
        names = [e["name"] for e in self.call("search", self.path("src"), ".h")[0]["entries"]]
        self.assertEqual(names, [".hidden"])

    def test_preview_reads_text_and_skips_binary(self):
        (self.home / "src/t.txt").write_text("one\ntwo\n")
        (self.home / "src/b.bin").write_bytes(b"\0\1\2")
        self.assertEqual(self.call("preview", self.path("src/t.txt"))[0]["text"], "one\ntwo")
        self.assertEqual(self.call("preview", self.path("src/b.bin"))[0]["text"], "")

    def test_answer_takes_only_a_request_id_and_writes_it_for_the_portal(self):
        o, _ = self.call("answer", "not-an-id", "{}")
        self.assertEqual(o["error"], "bad request id")
        o, _ = self.call("answer", "0" * 32, "not json")
        self.assertEqual(o["error"], "the answer is not JSON")
        ident = "ab" * 16
        o, _ = self.call("answer", ident, '{"response": 0, "paths": ["/x"]}')
        self.assertTrue(o["ok"])
        target = Path(self.home / "run/files-portal" / (ident + ".json"))
        self.assertEqual(json.loads(target.read_text()), {"response": 0, "paths": ["/x"]})

    def test_trash_and_paste_report_what_they_did_for_an_undo(self):
        o, _ = self.call("trash", self.path("src/a.txt"))
        self.assertEqual([m["from"] for m in o["moved"]], [self.path("src/a.txt")])
        self.assertTrue(o["moved"][0]["id"])
        o, _ = self.call("paste", "copy", self.path("dst"), self.path("src/sub") if (self.home / "src/sub").exists() else self.path("src/.hidden"))
        self.assertEqual(len(o["made"]), 1)
        self.assertTrue(Path(o["made"][0]).exists())

    def test_stat_tells_the_facts_of_a_path(self):
        o, _ = self.call("stat", self.path("src"))
        self.assertEqual((o["info"]["kind"], o["info"]["items"]), ("dir", 2))
        o, _ = self.call("stat", self.path("src/a.txt"))
        self.assertEqual((o["info"]["kind"], o["info"]["size"], o["info"]["mime"]), ("text", 1, "text/plain"))

    def test_batch_rename_swaps_names_without_clashing(self):
        (self.home / "src/one").write_text("1")
        (self.home / "src/two").write_text("2")
        o, _ = self.call("rename-all", json.dumps([[self.path("src/one"), "two"], [self.path("src/two"), "one"]]))
        self.assertEqual((o["done"], o["errors"]), (2, []))
        self.assertEqual((self.home / "src/two").read_text(), "1")
        self.assertEqual((self.home / "src/one").read_text(), "2")

    def test_search_takes_its_limits_and_preview_its_lines(self):
        for i in range(5):
            (self.home / f"src/note{i}.txt").write_text("x")
        o, _ = self.call("search", self.path("src"), "note", "3", "5")
        self.assertEqual((len(o["entries"]), o["truncated"]), (3, True))
        (self.home / "src/long.txt").write_text("\n".join(str(i) for i in range(50)))
        o, _ = self.call("preview", self.path("src/long.txt"), "10")
        self.assertEqual(len(o["text"].splitlines()), 10)

    def test_duplicates_group_by_content_not_by_name(self):
        (self.home / "src/sub").mkdir()
        (self.home / "src/one.txt").write_text("same")
        (self.home / "src/sub/two.txt").write_text("same")
        (self.home / "src/three.txt").write_text("other")
        o, _ = self.call("duplicates", self.path("src"))
        self.assertEqual(o["groups"], 1)
        self.assertEqual(sorted(e["name"] for e in o["entries"]), ["one.txt", "two.txt"])


if __name__ == "__main__":
    unittest.main()


class VolumesFrom(unittest.TestCase):
    """The "This computer" rows from fake findmnt and lsblk data (no disk is read)."""

    @classmethod
    def setUpClass(cls):
        sys.path.insert(0, str(SCRIPT.parent))
        import files
        cls.files = files

    def rows(self, mounts, blocks):
        nodes = list(self.files.block_nodes(blocks))
        return self.files.volumes_from(mounts, nodes, lambda p: (100, 40))

    def test_one_row_per_filesystem_and_pseudo_ones_are_left_out(self):
        mounts = [
            {"target": "/", "source": "/dev/nvme0n1p2", "fstype": "btrfs"},
            {"target": "/home", "source": "/dev/nvme0n1p2", "fstype": "btrfs"},
            {"target": "/proc", "source": "proc", "fstype": "proc"},
            {"target": "/tmp", "source": "tmpfs", "fstype": "tmpfs"},
            {"target": "/snap/core/1", "source": "/dev/loop0", "fstype": "squashfs"},
            {"target": "/mnt/bind", "source": "/dev/nvme0n1p2", "fstype": "btrfs"},
        ]
        blocks = [{"name": "nvme0n1p2", "path": "/dev/nvme0n1p2", "type": "part", "fstype": "btrfs",
                   "mountpoint": "/", "rm": "0", "hotplug": "0", "label": "", "size": "900G"}]
        rows = self.rows(mounts, blocks)
        self.assertEqual([r["mount"] for r in rows], ["/"])
        self.assertEqual(rows[0]["name"], "Root")
        self.assertEqual(sorted(rows[0]["mounts"]), ["/", "/home", "/mnt/bind"])
        self.assertEqual((rows[0]["total"], rows[0]["free"]), (100, 40))

    def test_network_and_removable_kinds_and_unmounted_drives_last(self):
        mounts = [
            {"target": "/mnt/nas", "source": "nas:/share", "fstype": "nfs4"},
            {"target": "/run/media/u/STICK", "source": "/dev/sdb1", "fstype": "vfat"},
        ]
        blocks = [
            {"name": "sdb", "path": "/dev/sdb", "type": "disk", "rm": "1", "hotplug": "1", "children": [
                {"name": "sdb1", "path": "/dev/sdb1", "type": "part", "fstype": "vfat", "label": "USB",
                 "mountpoint": "/run/media/u/STICK", "size": "8G"}]},
            {"name": "sdc1", "path": "/dev/sdc1", "type": "part", "fstype": "exfat", "label": "",
             "mountpoint": None, "rm": "1", "size": "16G"},
        ]
        rows = self.rows(mounts, blocks)
        self.assertEqual([(r["name"], r["kind"]) for r in rows],
                         [("nas", "network"), ("USB", "removable"), ("sdc1", "removable")])
        self.assertEqual(rows[2]["mount"], "")
        self.assertEqual(rows[2]["size"], "16G")

    def test_devices_tell_removable_drives_and_keep_unmounted_ones(self):
        blocks = [
            {"name": "sdb", "path": "/dev/sdb", "type": "disk", "rm": "1", "children": [
                {"name": "sdb1", "path": "/dev/sdb1", "type": "part", "fstype": "vfat", "label": "STICK",
                 "mountpoint": "/run/media/u/STICK", "size": "8G"}]},
            {"name": "sdc1", "path": "/dev/sdc1", "type": "part", "fstype": "exfat", "label": "",
             "mountpoint": None, "hotplug": "1", "size": "16G"},
            {"name": "sda2", "path": "/dev/sda2", "type": "part", "fstype": "ext4", "label": "root",
             "mountpoint": "/", "size": "100G"},
        ]
        nodes = list(self.files.block_nodes(blocks))
        devices = self.files.devices_from(nodes, lambda p: (100, 40))
        self.assertEqual([(d["name"], d["removable"], d["mount"]) for d in devices],
                         [("STICK", True, "/run/media/u/STICK"), ("sdc1", True, "")])
        self.assertEqual((devices[0]["total"], devices[0]["free"]), (100, 40))
        self.assertEqual((devices[1]["total"], devices[1]["free"]), (0, 0))

    def test_a_bind_mount_of_the_same_source_is_not_a_second_row(self):
        mounts = [
            {"target": "/home", "source": "/dev/sda2", "fstype": "ext4"},
            {"target": "/srv/home", "source": "/dev/sda2", "fstype": "ext4"},
        ]
        rows = self.rows(mounts, [])
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]["mount"], "/home")
