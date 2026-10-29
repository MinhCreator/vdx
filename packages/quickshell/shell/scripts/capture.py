#!/usr/bin/env python3
"""Capture output: save <temporary> <absolute target> [replace], discard/clipboard <temporary>.

Saving never replaces an existing destination unless explicitly requested.
A failed copy leaves the source available for another Save as attempt.
"""
import errno
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

from backend import fail, out


def copy_exclusive(source, target):
    created = False
    try:
        with source.open("rb") as src, target.open("xb") as dst:
            created = True
            shutil.copyfileobj(src, dst)
        shutil.copystat(source, target)
    except BaseException:
        if created:
            target.unlink(missing_ok=True)
        raise


def replace_across_filesystems(source, target):
    fd, name = tempfile.mkstemp(prefix=".capture-", dir=target.parent)
    os.close(fd)
    temporary = Path(name)
    try:
        shutil.copy2(source, temporary)
        os.replace(temporary, target)
    finally:
        temporary.unlink(missing_ok=True)
    source.unlink()


def save(source, target, replace=False):
    source, target = Path(source), Path(target)
    if not target.is_absolute():
        raise ValueError("Use an absolute file path")
    if not source.is_file():
        raise ValueError("The temporary capture is missing")
    if source.absolute() == target.absolute():
        return {"ok": True, "path": str(target)}
    target.parent.mkdir(parents=True, exist_ok=True)
    if replace:
        try:
            os.replace(source, target)
        except OSError as error:
            if error.errno != errno.EXDEV:
                raise
            replace_across_filesystems(source, target)
    else:
        try:
            # Same filesystem: retain metadata without copying a large video.
            try:
                os.link(source, target)
            except FileExistsError:
                raise
            except OSError:
                # Cross-device or a filesystem without hard links: reserve the
                # destination exclusively before copying, and remove partials.
                copy_exclusive(source, target)
        except FileExistsError:
            return {"ok": False, "exists": True, "error": "File already exists"}
        source.unlink()
    return {"ok": True, "path": str(target)}


def clipboard(source):
    # wl-copy forks the clipboard owner. Avoid captured pipes that a daemon
    # could inherit and keep open after the command itself has returned.
    with open(source, "rb") as image, tempfile.TemporaryFile() as errors:
        result = subprocess.run(["wl-copy", "--type", "image/png"], stdin=image,
                                stdout=subprocess.DEVNULL, stderr=errors, timeout=15)
        if result.returncode:
            errors.seek(0)
            return {"ok": False, "error": errors.read().decode("utf-8", "replace").strip() or "Could not copy screenshot"}
    return {"ok": True}


def main():
    args = sys.argv[1:]
    try:
        if len(args) in (3, 4) and args[0] == "save" and (len(args) == 3 or args[3] == "replace"):
            out(save(args[1], args[2], len(args) == 4))
        elif len(args) == 2 and args[0] == "discard":
            Path(args[1]).unlink(missing_ok=True)
            out({"ok": True})
        elif len(args) == 2 and args[0] == "clipboard":
            out(clipboard(args[1]))
        else:
            fail("usage: capture.py save <temporary> <absolute target> [replace] | discard/clipboard <temporary>")
    except (OSError, ValueError, subprocess.TimeoutExpired) as error:
        fail(str(error))


if __name__ == "__main__":
    main()
