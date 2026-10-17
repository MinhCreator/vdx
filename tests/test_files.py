"""The file manager's backend (packages/quickshell/shell/scripts/files.py): what a
listing, a paste, a trash, a restore and a search do to a folder — run in a sandbox HOME."""

from __future__ import annotations

import json
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
