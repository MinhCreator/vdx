#!/usr/bin/env python3
"""Change the user's own password for the Shell Manager (Profile). One JSON object.

    password.py change           reads one line {"current": "...", "new": "..."} from stdin
                                 {"ok": true} or {"ok": false, "error": "..."}

It drives the system's own `passwd` on a pseudo-terminal, so PAM checks the
current password and the new one's strength as everywhere else; the passwords
travel by stdin and the pty, never by a command line. Errors: {"ok": false, "error": "..."}."""
import json, os, pty, select, sys, time
from backend import out, fail

TIMEOUT = 20

# what passwd's last line says -> what the user reads
ERRORS = (
    ("authentication failure", "Wrong current password"),
    ("too short", "The new password is too short"),
    ("too simple", "The new password is too simple"),
    ("bad password", "The new password is too weak"),
    ("do not match", "The two passwords do not match"),
    ("is the same", "The new password is the same as the old one"),
)


def explain(text):
    low = text.lower()
    for needle, message in ERRORS:
        if needle in low:
            return message
    lines = [l.strip() for l in text.replace("\r", "\n").split("\n") if l.strip()]
    return (lines[-1] if lines else "passwd failed")[:160]


def change(current, new):
    if not current or not new:
        fail("Both passwords are needed")
    pid, fd = pty.fork()
    if pid == 0:
        os.environ["LC_ALL"] = "C"
        os.execvp("passwd", ["passwd"])
    seen = ""        # everything passwd printed
    fresh = ""       # what it printed since the last answer
    retyped = False
    deadline = time.time() + TIMEOUT
    while time.time() < deadline:
        ready, _, _ = select.select([fd], [], [], 0.2)
        if ready:
            try:
                data = os.read(fd, 4096).decode(errors="replace")
            except OSError:
                break
            if not data:
                break
            seen += data
            fresh += data
        low = fresh.lower()
        if low.rstrip().endswith(":"):
            if "retype" in low or "again" in low:
                os.write(fd, (new + "\n").encode()); retyped = True
            elif "current" in low or "(current)" in low:
                os.write(fd, (current + "\n").encode())
            elif "new" in low:
                os.write(fd, (new + "\n").encode())
            else:
                continue
            fresh = ""
    if time.time() >= deadline:
        os.kill(pid, 9)
        os.waitpid(pid, 0)
        fail("passwd did not answer")
    _, status = os.waitpid(pid, 0)
    if os.WIFEXITED(status) and os.WEXITSTATUS(status) == 0 and retyped:
        out({"ok": True})
    # the typed answers are echoed by nobody, but never hand a password back
    message = explain(seen)
    for secret in (current, new):
        message = message.replace(secret, "…")
    fail(message)


def main():
    if sys.argv[1:] != ["change"]:
        fail("usage: password.py change")
    try:
        data = json.loads(sys.stdin.readline())
        change(str(data.get("current", "")), str(data.get("new", "")))
    except (ValueError, AttributeError):
        fail("bad request")


if __name__ == "__main__":
    main()
