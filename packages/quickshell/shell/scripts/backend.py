#!/usr/bin/env python3
"""What every backend in this folder shares: one JSON reply with an exit code
(out, fail) and a command runner that never raises (run). A script imports it
with `from backend import out, fail, run`: when a script runs, its folder is on
sys.path, so the link in ~/.config/quickshell/shell/scripts works too.

    out({"ok": True, ...})        prints the JSON; exit 0
    out({"ok": False, ...})       prints it; exit 1
    fail(msg)                     out({"ok": False, "error": msg})
    run(args, timeout=10)         CompletedProcess (text, captured), or None when the
                                  program is missing or it timed out"""
import json, subprocess, sys


def out(obj):
    print(json.dumps(obj))
    sys.exit(0 if obj.get("ok") else 1)


def fail(msg):
    out({"ok": False, "error": msg})


def run(args, timeout=10):
    try:
        return subprocess.run(args, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return None
