"""Run a windowless Quickshell fixture with its own runtime and state."""
from __future__ import annotations

import os
from pathlib import Path
import subprocess

SHELL = Path(__file__).resolve().parent.parent / "packages/quickshell/shell"


def run_quickshell(root, timeout=8):
    runtime = root / "run"
    runtime.mkdir(mode=0o700, exist_ok=True)
    env = dict(os.environ, QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software",
               XDG_RUNTIME_DIR=str(runtime), XDG_STATE_HOME=str(root / "state"),
               XDG_CACHE_HOME=str(root / "cache"))
    result = subprocess.run(["qs", "--no-color", "-p", str(root)], env=env,
                            capture_output=True, text=True, timeout=timeout)
    output = result.stdout + result.stderr
    if result.returncode != 0:
        raise AssertionError(f"Quickshell exited with {result.returncode}:\n{output}")
    return output
