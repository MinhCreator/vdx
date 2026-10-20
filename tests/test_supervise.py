"""supervise.sh: a kill ends it, a config that does not load is one toast and a
wait for a fix (not a crash loop), five crashes in a minute stop it."""

from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SUPERVISE = ROOT / "packages/quickshell/shell/scripts/supervise.sh"

# a qs that ends with the next code of codes.txt; on 255 it leaves a log of a
# config that did not load and makes shell.qml newer (the fix)
FAKE_QS = textwrap.dedent("""\
    #!/usr/bin/env bash
    echo "$*" >> "$SANDBOX/qs.calls"
    code=$(head -1 "$SANDBOX/codes.txt"); sed -i 1d "$SANDBOX/codes.txt"
    if [[ $code == 255 ]]; then
      mkdir -p "$XDG_RUNTIME_DIR/quickshell/by-pid/$$"
      printf 'ERROR: Failed to load configuration\\nERROR:   caused by @shell.qml[2:3]: Nope is not a type\\n' \\
        > "$XDG_RUNTIME_DIR/quickshell/by-pid/$$/log.log"
      touch -d "@$(( $(date +%s) + 5 ))" "$SANDBOX/shell/shell.qml"
    fi
    exit "$code"
    """)


class Supervise(unittest.TestCase):
    def run_with(self, codes):
        tmp = Path(self.enterContext(tempfile.TemporaryDirectory()))
        scripts = tmp / "shell/scripts"
        scripts.mkdir(parents=True)
        shutil.copy(SUPERVISE, scripts / "supervise.sh")
        (scripts / "settings_migrate.py").write_text("")
        (tmp / "shell/shell.qml").write_text("")
        (tmp / "codes.txt").write_text("".join(f"{c}\n" for c in codes))
        bin_ = tmp / "bin"
        bin_.mkdir()
        (bin_ / "qs").write_text(FAKE_QS)
        (bin_ / "notify-send").write_text('#!/usr/bin/env bash\necho "$*" >> "$SANDBOX/toasts"\n')
        (bin_ / "makoctl").write_text("#!/usr/bin/env bash\n")
        for f in bin_.iterdir():
            f.chmod(0o755)
        (tmp / "run").mkdir()
        env = {k: v for k, v in os.environ.items() if k != "WAYLAND_DISPLAY"}
        env.update(PATH=f"{bin_}:{env['PATH']}", SANDBOX=str(tmp), XDG_RUNTIME_DIR=str(tmp / "run"))
        r = subprocess.run(["bash", str(scripts / "supervise.sh")], env=env, timeout=30)
        calls = (tmp / "qs.calls").read_text().splitlines()
        toasts = (tmp / "toasts").read_text().splitlines() if (tmp / "toasts").exists() else []
        return r.returncode, len(calls), toasts

    def test_a_kill_ends_it(self):
        self.assertEqual(self.run_with([143]), (0, 1, []))

    def test_a_config_error_is_one_toast_and_a_retry_on_a_fix(self):
        code, starts, toasts = self.run_with([255, 255, 0])
        self.assertEqual((code, starts), (0, 3))
        self.assertEqual(len(toasts), 1)
        self.assertIn("config has an error", toasts[0])
        self.assertIn("Nope is not a type", toasts[0])
        self.assertNotIn("crashing", toasts[0])

    def test_five_crashes_stop_it(self):
        code, starts, toasts = self.run_with([139] * 6)
        self.assertEqual((code, starts), (1, 5))
        self.assertEqual(len(toasts), 1)
        self.assertIn("keeps crashing", toasts[0])


if __name__ == "__main__":
    unittest.main()
