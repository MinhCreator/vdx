"""dotfiles installer — `setup` (the steps are in steps.py), `bootstrap` and `secrets`."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

from . import steps
from .links import cmd_verify
from .paths import ROOT, SEED, STATE, TGT
from .preflight import preflight
from .ui import added, confirm, dim, err, heading, note, ok, short, warn


def cmd_bootstrap(args) -> int:
    heading("Seeding secrets")
    jobs = [
        (SEED / "env.example", TGT / "secrets" / "env", 0o600, "secrets env"),
    ]
    for src, tgt, mode, label in jobs:
        if not src.is_file():
            continue
        if tgt.exists() and not getattr(args, "force", False):
            note(f"{label}: {short(tgt)} exists, kept")
            continue
        tgt.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, tgt)
        os.chmod(tgt, mode)
        added(f"{label} -> {short(tgt)}")
    return 0


def cmd_secrets(args) -> int:
    """Secret files from the private repo (private/, see private/secrets.py)."""
    script = ROOT / "private" / "secrets.py"
    heading("Secrets (private/)")
    if not script.is_file():
        note("private/ is not cloned: git clone git@github.com:diominvd/secrets.git private")
        return 0
    action = getattr(args, "s_action", "status")
    sys.stdout.flush()
    subprocess.run([sys.executable, "-I", str(script), action], check=True)
    return 0


class Log:
    """stdout copied, colours stripped, into the setup's log file."""

    def __init__(self, path: Path, out):
        self.file, self.out = path.open("a"), out

    def write(self, text: str) -> int:
        self.file.write(ANSI.sub("", text))
        return self.out.write(text)

    def flush(self) -> None:
        self.file.flush()
        self.out.flush()

    def isatty(self) -> bool:
        return self.out.isatty()


ANSI = re.compile(r"\x1b\[[0-9;]*m")


def cmd_setup(args) -> int:
    """A fresh machine, or one to bring up to date: preflight, the plan, then
    every step with something to do. Idempotent; a failed step stops the run,
    and the next run skips what is done."""
    STATE.mkdir(parents=True, exist_ok=True)
    stamp = time.strftime("%Y-%m-%dT%H-%M-%S")
    log = STATE / f"setup-{stamp}.log"
    real, sys.stdout = sys.stdout, Log(log, sys.stdout)
    try:
        return setup(args, stamp, log)
    finally:
        sys.stdout.flush()
        sys.stdout = real


def setup(args, stamp: str, log: Path) -> int:
    dry = getattr(args, "dry_run", False)
    heading("Setup" + (dim(" (dry run: nothing is changed)") if dry else ""))
    if not preflight():
        return 1
    ctx = steps.context(args)
    heading(f"Plan {dim('· ' + str(len(ctx.on)) + ' components · ./install.py components')}")
    rows = steps.plan(ctx)
    steps.show_plan(rows)
    todo = [s for s, pending, _ in rows if pending]
    if dry or not todo:
        print()
        ok("nothing to do" if not todo else f"{len(todo)} step(s) would run")
        return 0
    if not confirm(f"Run {len(todo)} step(s)? (sudo is asked for packages, /etc and services)", args):
        return 1
    args.yes = True
    journal = {"started": stamp, "log": str(log), "steps": {}}
    for step in todo:
        heading(step.title)
        try:
            if step.pending(ctx):               # an earlier step may have done it
                step.run(ctx)
            journal["steps"][step.name] = "done"
        except (subprocess.CalledProcessError, RuntimeError, OSError) as e:
            journal["steps"][step.name] = f"failed: {e}"
            (STATE / "setup.json").write_text(json.dumps(journal, indent=2) + "\n")
            err(f"{step.title}: {e}")
            note(f"fix it and run setup again: what is done is skipped · log: {short(log)}")
            return 1
    (STATE / "setup.json").write_text(json.dumps({**journal, "finished": time.strftime("%Y-%m-%dT%H-%M-%S")}, indent=2) + "\n")
    code = cmd_verify(args)
    left = [line for _, _, manual in steps.plan(ctx) for line in manual]
    if left:
        heading("Left to do by hand")
        for line in left:
            warn(line)
    note(f"log: {short(log)}")
    return code
