#!/usr/bin/env python3
"""Backups for the shell (apps/backup) and for the terminal, the same commands.
Encrypted snapshots with restic: your home, /etc and the list of installed
packages go to a repository (a folder on a drive, or any restic repository);
a systemd user timer runs them on a schedule.

    backup.py status                    what is set up and the last run
    backup.py init [--repo PATH]        create the repository (makes the password file)
    backup.py password                  the repository's password: keep a copy somewhere safe
    backup.py config                    the settings
    backup.py config set <json>         change some: '{"sources": {"etc": false}}'
    backup.py run [--auto]              back up now (--auto is what the timer runs)
    backup.py snapshots                 every snapshot
    backup.py ls <snapshot> [PATH]      the folders and files of a snapshot
    backup.py restore <snapshot> [--include PATH]… [--target DIR]
                                        copy into DIR (default ~/Restore/…); never over existing files
    backup.py packages <snapshot>       the steps to rebuild the system: pacman packages, services, groups
    backup.py aur <snapshot>            the AUR packages it lists (yay builds them, in a terminal)
    backup.py ai [--model M]            Claude suggests what to leave out: sends folder names and sizes, never contents
    backup.py guide                     how to restore after a breakage, step by step
    backup.py size                      how big the backups are (on disk, and what the newest restores to)
    backup.py sizes <snapshot> [PATH]   the size of each folder or file under PATH
    backup.py pick [--start DIR]        pick any folder in the Files window: the repository goes there
    backup.py root-plan                 the root pass: /etc and Bluetooth, read as root (the shell asks the password)
    backup.py forget <snapshot>… [--prune]
    backup.py verify [--deep]           check the repository (--deep reads every pack)
    backup.py schedule off|daily|weekly [--time HH:MM]

Without this script, restic reads the same repository:
    restic -r REPO --password-file ~/.local/state/dotfiles/restic/password snapshots

--json is the shell's form: progress lines, then one JSON reply. Errors:
{"ok": false, "error": "..."}. A reply's "message" is the sentence for a person."""
import argparse, datetime as dt, fcntl, getpass, json, os, re, secrets, shlex, shutil, signal, subprocess, sys, tempfile, time
from contextlib import contextmanager
from pathlib import Path

HOME = Path.home()
STATE = HOME / ".local/state/dotfiles"
# its own folder: the installer keeps its replaced-file copies in STATE / "backup"
DIR = STATE / "restic"
CONFIG = DIR / "config.json"
PASSWORD = DIR / "password"
LAST = DIR / "last.json"
LOCK = DIR / "lock"
PACKAGES = STATE / "packages.txt"
UNIT_DIR = HOME / ".config/systemd/user"
UNIT = "dotfiles-backup"
SCRIPT = Path(__file__).resolve()
JSON = False

# readable by root only: Wi-Fi passwords, logins, Bluetooth pairings, server host keys
ROOT_PATHS = ["/etc", "/var/lib/bluetooth"]
NAME = re.compile(r"^[A-Za-z0-9@._+-]+$")
SNAP = re.compile(r"^(latest|[0-9a-f]{6,64})$")
TIME = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")
REMOTE = re.compile(r"^[a-z0-9+]+:")      # sftp:…, s3:…, rest:… — not a local folder
SECTIONS = {"# native": "native", "# foreign": "foreign", "# services": "services", "# groups": "groups"}

DEFAULTS = {
    "repo": "",
    "sources": {"home": True, "etc": True, "packages": True, "root": True},
    "extra": [],
    # restic: a pattern with a slash is a path, one without matches any name (node_modules)
    "excludes": [str(HOME / ".cache"), str(HOME / ".local/share/Trash"), str(DIR),
                 str(HOME / ".npm"), str(HOME / ".cargo/registry"), str(HOME / ".local/share/uv"),
                 "node_modules", "__pycache__", "GPUCache", "Code Cache", "ShaderCache",
                 "/etc/shadow", "/etc/gshadow", "/etc/shadow-", "/etc/gshadow-"],
    "keep": {"on": True, "daily": 7, "weekly": 4, "monthly": 6},
    "schedule": {"mode": "off", "time": "03:00"},
    "notify": True,
}


class Failure(Exception):
    pass


# ---- output ----

def reply(obj):
    ok = obj.get("ok") is True
    if JSON:
        print(json.dumps(obj), flush=True)
    elif ok:
        print(obj.get("text") or obj.get("message", "done"))
    else:
        print(obj.get("error", "failed"), file=sys.stderr)
    sys.exit(0 if ok else 1)


def progress(percent):
    if JSON:
        print(json.dumps({"progress": percent}), flush=True)
    else:
        print(f"\r{percent:3d}%", end="", flush=True)


def size_text(n):
    for unit in ("B", "KB", "MB", "GB", "TB"):
        if n < 1024 or unit == "TB":
            return f"{n:.0f} {unit}" if unit == "B" else f"{n:.1f} {unit}"
        n /= 1024


def ago(ts):
    if not ts:
        return "never"
    s = time.time() - ts
    for limit, div, word in ((3600, 60, "min"), (86400, 3600, "h"), (1e12, 86400, "days")):
        if s < limit:
            return f"{max(1, int(s // div))} {word} ago"


# ---- config ----

def merge(base, new):
    for k, v in new.items():
        if isinstance(v, dict) and isinstance(base.get(k), dict):
            merge(base[k], v)
        else:
            base[k] = v
    return base


def load_config():
    cfg = json.loads(json.dumps(DEFAULTS))
    if CONFIG.exists():
        try:
            merge(cfg, json.loads(CONFIG.read_text()))
        except ValueError:
            raise Failure(f"{CONFIG} is not valid JSON") from None
    return cfg


def check_config(cfg):
    """The problem with a config, or None."""
    if not isinstance(cfg["repo"], str):
        return "repo must be a path or a restic repository"
    if not all(isinstance(v, bool) for v in [*cfg["sources"].values(), cfg["keep"]["on"], cfg["notify"]]):
        return "sources, keep.on and notify are on/off"
    if not all(isinstance(cfg["keep"][k], int) and 0 <= cfg["keep"][k] <= 999 for k in ("daily", "weekly", "monthly")):
        return "keep counts are whole numbers, 0 to 999"
    if not all(isinstance(p, str) and p.startswith("/") for p in cfg["extra"]):
        return "extra folders are absolute paths"
    if not all(isinstance(p, str) and p.strip() and "\n" not in p for p in cfg["excludes"]):
        return "excludes are patterns, one per entry"
    if cfg["schedule"]["mode"] not in ("off", "daily", "weekly") or not TIME.match(cfg["schedule"]["time"]):
        return "schedule is off, daily or weekly, at HH:MM"
    return None


def save_config(cfg):
    problem = check_config(cfg)
    if problem:
        raise Failure(problem)
    write_private(CONFIG, json.dumps(cfg, indent=2) + "\n")


def write_private(path, text):
    path.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
    tmp = path.with_name(path.name + ".tmp")
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def is_local(repo):
    return not REMOTE.match(repo)


def require_repo(cfg=None):
    repo = (cfg or load_config())["repo"]
    if not repo:
        raise Failure("no repository yet: set one in Settings, or backup.py init --repo PATH")
    return repo


def configured():
    return bool(load_config()["repo"]) and PASSWORD.exists()


def require_password():
    if not PASSWORD.exists():
        raise Failure("no password yet: backup.py init makes one")


# ---- restic ----

def need_restic():
    if shutil.which("restic") is None:
        raise Failure("restic is not installed: pacman -S restic")


def explain(proc):
    lines = [l.strip() for l in proc.stderr.splitlines() if l.strip()]
    fatal = [l for l in lines if "Fatal" in l or "error" in l.lower()]
    return ((fatal or lines or ["restic failed"])[-1])[:200]


def restic(args, repo=None, check=True):
    need_restic()
    require_password()
    cmd = ["restic", "-r", repo or require_repo(), "--password-file", str(PASSWORD), *args]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True)
    except OSError as e:
        raise Failure(str(e)) from None
    if check and proc.returncode != 0:
        raise Failure(explain(proc))
    return proc


def json_lines(text):
    rows = []
    for line in text.splitlines():
        try:
            rows.append(json.loads(line))
        except ValueError:
            pass
    return rows


def epoch(stamp):
    # restic writes nanoseconds; Python reads microseconds
    stamp = re.sub(r"(\.\d{6})\d+", r"\1", stamp).replace("Z", "+00:00")
    return dt.datetime.fromisoformat(stamp).timestamp()


@contextmanager
def locked():
    DIR.mkdir(parents=True, exist_ok=True, mode=0o700)
    handle = open(LOCK, "w")
    try:
        fcntl.flock(handle, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except BlockingIOError:
        handle.close()
        raise Failure("another backup or restore is running") from None
    try:
        yield
    finally:
        handle.close()


def snap_arg(value):
    if not SNAP.match(value):
        raise Failure(f"not a snapshot: {value}")
    return value


def read_last():
    try:
        return json.loads(LAST.read_text())
    except (OSError, ValueError):
        return None


# ---- sources ----

def pacman_names(flag):
    proc = subprocess.run(["pacman", "-Qqe" + flag], capture_output=True, text=True)
    return [l for l in proc.stdout.split() if NAME.match(l)]


def enabled_units():
    try:
        proc = subprocess.run(["systemctl", "list-unit-files", "--state=enabled", "--no-legend", "--no-pager"],
                              capture_output=True, text=True)
    except OSError:
        return []
    names = [l.split()[0] for l in proc.stdout.splitlines() if l.split()]
    # a template (getty@.service) has no instance to enable: its instances are listed as they are
    return [n for n in names if NAME.match(n) and "@." not in n]


def user_groups():
    primary = subprocess.run(["id", "-gn"], capture_output=True, text=True).stdout.strip()
    groups = subprocess.run(["id", "-Gn"], capture_output=True, text=True).stdout.split()
    return [g for g in groups if g != primary and NAME.match(g)]


def write_packages():
    """The system list: what pacman installed, the services enabled, the user's groups."""
    native, foreign = pacman_names("n"), pacman_names("m")
    services, groups = enabled_units(), user_groups()
    parts = [("# native", native), ("# foreign", foreign), ("# services", services), ("# groups", groups)]
    write_private(PACKAGES, "".join(head + "\n" + "\n".join(names) + "\n" for head, names in parts))
    return {"native": len(native), "foreign": len(foreign), "services": len(services), "groups": len(groups)}


def read_sections(text):
    out = {key: [] for key in SECTIONS.values()}
    section = None
    for line in text.splitlines():
        line = line.strip()
        if line in SECTIONS:
            section = SECTIONS[line]
        elif line and not line.startswith("#") and section:
            out[section].append(line)
    return out


def sources(cfg):
    paths = []
    if cfg["sources"]["home"]:
        paths.append(str(HOME))
    if cfg["sources"]["packages"]:
        write_packages()
        if not cfg["sources"]["home"]:       # home already holds the list
            paths.append(str(PACKAGES))
    if cfg["sources"]["etc"]:
        paths.append("/etc")
    return paths + cfg["extra"]


# ---- commands ----

def cmd_status(a):
    cfg = load_config()
    last = read_last()
    configured = bool(cfg["repo"]) and PASSWORD.exists()
    text = [f"Repository: {cfg['repo'] or 'not set'}",
            f"Password: {'in ' + str(PASSWORD) if PASSWORD.exists() else 'none yet'}",
            f"Schedule: {cfg['schedule']['mode']}" + (f" at {cfg['schedule']['time']}" if cfg["schedule"]["mode"] != "off" else "")]
    if last:
        text.append(f"Last run: {ago(last.get('ts'))} · {last.get('message', '')}")
    else:
        text.append("Last run: never")
    return {"ok": True, "configured": configured, "restic": shutil.which("restic") is not None,
            "claude": shutil.which("claude") is not None,
            "config": cfg, "last": last, "text": "\n".join(text),
            "message": "Ready" if configured else "Not set up yet"}


def cmd_init(a):
    cfg = load_config()
    repo = a.repo or cfg["repo"]
    if not repo:
        raise Failure("give a repository: init --repo PATH")
    need_restic()
    if is_local(repo) and not Path(repo).parent.is_dir():
        raise Failure(f"{Path(repo).parent} is missing: is the drive mounted?")
    created = not PASSWORD.exists()
    if created:
        write_private(PASSWORD, secrets.token_urlsafe(32) + "\n")
    proc = restic(["init"], repo=repo, check=False)
    if proc.returncode != 0:
        if "already" not in proc.stderr and "exists" not in proc.stderr:
            if created:
                PASSWORD.unlink()
            raise Failure(explain(proc))
        # a repository is there: it is used when the password in the file opens it
        if created:
            PASSWORD.unlink()
            raise Failure(f"{repo} holds a repository already: its password goes into {PASSWORD}")
        if restic(["cat", "config"], repo=repo, check=False).returncode != 0:
            raise Failure("the password in the file does not open the repository at " + repo)
        cfg["repo"] = repo
        save_config(cfg)
        return {"ok": True, "repo": repo, "generated": False, "message": f"Using the repository at {repo}"}
    cfg["repo"] = repo
    save_config(cfg)
    message = f"Repository ready at {repo}"
    if created:
        message += ". The password is in " + str(PASSWORD) + ": keep a copy somewhere safe"
    return {"ok": True, "repo": repo, "generated": created, "message": message}


def cmd_password(a):
    if not PASSWORD.exists():
        raise Failure("no password yet: backup.py init makes one")
    password = PASSWORD.read_text().strip()
    return {"ok": True, "password": password, "message": password}


def cmd_config(a):
    if a.action == "set":
        try:
            change = json.loads(a.value)
        except ValueError:
            raise Failure("the change is not JSON") from None
        cfg = merge(load_config(), change)
        save_config(cfg)
        return {"ok": True, "config": cfg, "message": "Saved"}
    cfg = load_config()
    return {"ok": True, "config": cfg, "text": json.dumps(cfg, indent=2), "message": "Settings"}


def cmd_run(a):
    cfg = load_config()
    repo = require_repo(cfg)
    require_password()
    with locked():
        paths = sources(cfg)
        if not paths:
            raise Failure("nothing is selected to back up")
        missing = [p for p in cfg["extra"] if not os.path.exists(p)]
        if missing:
            raise Failure(f"not there: {missing[0]}")
        need_restic()
        nice = ["nice", "-n", "19", "ionice", "-c", "3"] if shutil.which("nice") and shutil.which("ionice") else []
        args = ["-r", repo, "--password-file", str(PASSWORD), "backup", "--json", "--exclude-caches",
                "--tag", "auto" if a.auto else "manual"]
        for pattern in cfg["excludes"]:
            args += ["--exclude", pattern]
        with tempfile.TemporaryFile("w+") as errors:
            proc = subprocess.Popen(nice + ["restic", *args, *paths], stdout=subprocess.PIPE, stderr=errors, text=True)
            # a stop (the shell's cancel, Ctrl+C) goes to restic, which finishes its pack and exits
            stopped = []

            def stop(signum, frame):
                stopped.append(signum)
                proc.send_signal(signal.SIGINT)

            signal.signal(signal.SIGINT, stop)
            signal.signal(signal.SIGTERM, stop)
            summary = None
            for line in proc.stdout:
                try:
                    msg = json.loads(line)
                except ValueError:
                    continue
                if msg.get("message_type") == "status" and "percent_done" in msg:
                    progress(int(msg["percent_done"] * 100))
                elif msg.get("message_type") == "summary":
                    summary = msg
            proc.wait()
            errors.seek(0)
            err = errors.read()
        if stopped:
            record(False, "Cancelled", a.auto)
            raise Failure("cancelled")
        code = proc.returncode
        # 3: some files could not be read; the snapshot is still there
        if code not in (0, 3):
            text = explain(subprocess.CompletedProcess([], code, "", err))
            record(False, text, a.auto)
            raise Failure(text)
        size = int((summary or {}).get("total_bytes_processed", 0))
        message = f"Backed up {size_text(size)}"
        if code == 3:
            skipped = err.lower().count("permission denied")
            message += f" · {skipped} root-only files left out" if skipped else " · some files could not be read"
        pruned = prune(cfg) if cfg["keep"]["on"] else None
        record(True, message, a.auto, snapshot=(summary or {}).get("snapshot_id", "")[:8], size=size, partial=code == 3)
        if cfg["notify"] and a.auto:
            notify("Backup done" if code == 0 else "Backup done, with gaps", message)
        return {"ok": True, "snapshot": (summary or {}).get("snapshot_id", "")[:8], "size": size,
                "partial": code == 3, "pruned": pruned, "message": message}


def prune(cfg):
    """Keep the newest snapshots by the counts; only after a good backup."""
    keep = cfg["keep"]
    proc = restic(["forget", "--group-by", "host,tags", "--prune", "--keep-daily", str(keep["daily"]),
                   "--keep-weekly", str(keep["weekly"]), "--keep-monthly", str(keep["monthly"])], check=False)
    return proc.returncode == 0


def record(ok, message, auto, **extra):
    write_private(LAST, json.dumps({"ts": time.time(), "ok": ok, "message": message, "auto": auto, **extra}) + "\n")


def notify(title, body):
    if shutil.which("notify-send"):
        subprocess.run(["notify-send", "-a", "Backup", title, body], capture_output=True)


def cmd_snapshots(a):
    if not configured():
        return {"ok": True, "snapshots": [], "text": "No repository yet", "message": "No repository yet"}
    proc = restic(["snapshots", "--json"])
    rows = []
    for s in json.loads(proc.stdout or "[]") or []:
        rows.append({"id": s["id"], "short": s["short_id"], "ts": epoch(s["time"]), "tags": s.get("tags") or [],
                     "paths": s.get("paths") or [], "size": (s.get("summary") or {}).get("total_bytes_processed", 0)})
    rows.sort(key=lambda r: r["ts"], reverse=True)
    text = "\n".join(f"{r['short']}  {dt.datetime.fromtimestamp(r['ts']):%Y-%m-%d %H:%M}  {size_text(r['size']):>9}  "
                     f"{','.join(r['tags']) or '-':<8} {' '.join(r['paths'])}" for r in rows)
    return {"ok": True, "snapshots": rows, "text": text or "No snapshots yet", "message": f"{len(rows)} snapshots"}


def cmd_ls(a):
    snap_arg(a.snapshot)
    path = (a.path or "/").rstrip("/") or "/"
    proc = restic(["ls", "--json", a.snapshot, path])
    entries = []
    for node in json_lines(proc.stdout):
        if node.get("struct_type") != "node" or node.get("path") == path:
            continue
        if os.path.dirname(node["path"]) != path:
            continue
        entries.append({"name": node["name"], "path": node["path"], "dir": node["type"] == "dir",
                        "size": node.get("size", 0), "ts": epoch(node["mtime"]) if node.get("mtime") else 0})
    entries.sort(key=lambda e: (not e["dir"], e["name"].lower()))
    text = "\n".join(("/" if e["dir"] else " ") + e["name"] for e in entries)
    return {"ok": True, "entries": entries, "path": path, "text": text or "Empty", "message": f"{len(entries)} entries"}


def cmd_restore(a):
    snap_arg(a.snapshot)
    for p in a.include:
        if not p.startswith("/"):
            raise Failure(f"a path in the snapshot is absolute: {p}")
    target = Path(a.target).expanduser() if a.target else HOME / "Restore" / time.strftime("restore-%Y-%m-%d-%H%M%S")
    if target.exists() and (not target.is_dir() or any(target.iterdir())):
        raise Failure(f"{target} is not an empty folder")
    with locked():
        target.mkdir(parents=True, exist_ok=True)
        args = ["restore", a.snapshot, "--target", str(target)]
        for p in a.include:
            args += ["--include", p]
        restic(args)
    return {"ok": True, "target": str(target), "message": f"Restored to {target}"}


def snapshot_lists(snap):
    snap_arg(snap)
    with tempfile.TemporaryDirectory(prefix="backup-lists-") as tmp:
        restic(["restore", snap, "--target", tmp, "--include", str(PACKAGES)])
        listed = Path(tmp, str(PACKAGES).lstrip("/"))
        if not listed.exists():
            raise Failure("the snapshot holds no system list")
        lists = read_sections(listed.read_text())
    for names in lists.values():
        bad = [n for n in names if not NAME.match(n)]
        if bad:
            raise Failure(f"odd name in the system list: {bad[0]}")
    return lists


def cmd_packages(a):
    """The steps that rebuild the system part of the list (for RootService): the repository
    packages, the services enabled before, the groups. AUR packages are not here: see `aur`."""
    lists = snapshot_lists(a.snapshot)
    native, services, groups = lists["native"], lists["services"], lists["groups"]
    if not native:
        raise Failure("the list names no packages from the repositories")
    user = getpass.getuser()
    install = "pacman -S --needed --noconfirm " + shlex.join(native)
    steps = [{"label": f"Install {len(native)} packages", "what": "from the repositories, pacman", "command": install}]
    lines = ["set -e", install]
    if services:
        # one by one: a unit that is gone now does not stop the others
        enable = "for u in " + shlex.join(services) + "; do systemctl enable \"$u\" || echo \"skipped $u\"; done"
        steps.append({"label": f"Enable {len(services)} services", "what": "the ones on before", "command": enable})
        lines.append(enable)
    if groups:
        add = f"for g in {shlex.join(groups)}; do getent group \"$g\" >/dev/null && usermod -aG \"$g\" {shlex.quote(user)}; done"
        steps.append({"label": f"Add {user} to {len(groups)} groups", "what": "as before", "command": add})
        lines.append(add)
    message = f"{len(native)} packages, {len(services)} services, {len(groups)} groups"
    if lists["foreign"]:
        message += f" · {len(lists['foreign'])} AUR packages: their own button"
    return {"ok": True, "steps": steps, "script": "\n".join(lines) + "\n", "aur": lists["foreign"],
            "message": message}


# what the AI may never leave out: the dotfiles, keys and settings, and every folder holding them
KEEP = [HOME, HOME / ".dotfiles", HOME / ".ssh", HOME / ".gnupg", HOME / ".config", HOME / ".local",
        HOME / ".local/state", HOME / ".local/share", HOME / ".local/share/keyrings"]

AI_PROMPT = """You help decide what an encrypted backup of a Linux (Arch) user's home folder should leave out.
The backup must restore the whole working system after a breakage: their files, settings, keys,
application data and the dotfiles repository are kept. Below are the biggest folders of the home
folder: path (~ is home), size in MB, days since it last changed. You see no contents.

Suggest at most 12 entries from THIS LIST to leave out: caches, regenerable build output and
downloaded dependencies (node_modules, target, .venv, package caches, browser code caches), large
media that can be fetched again (game installs, virtual machine images, ISOs). Never suggest anything
that may hold the user's own data, settings or keys, and never a folder that contains such things.
Skip what you are unsure of.

Answer with ONLY this JSON, nothing else:
{"suggestions": [{"path": "<exactly as listed>", "why": "<under 70 characters>", "risk": "low" | "medium"}]}
"""


def claude_env():
    """The environment for `claude -p`: the signed-in account, not an API key left in the session."""
    return {k: v for k, v in os.environ.items()
            if k != "ANTHROPIC_API_KEY" and k != "CLAUDECODE" and not k.startswith("CLAUDE_CODE_")}


def home_listing():
    """The biggest folders of ~ (two levels, this filesystem): path, size, days since changed."""
    try:
        proc = subprocess.run(["du", "-b", "-x", "-d", "2", str(HOME)], capture_output=True, text=True, timeout=180)
    except (OSError, subprocess.TimeoutExpired):
        raise Failure("could not measure the home folder") from None
    rows = []
    for line in proc.stdout.splitlines():
        size, _, path = line.partition("\t")
        if not size.isdigit() or path == str(HOME) or int(size) < 20 * 2 ** 20:
            continue
        try:
            days = int((time.time() - Path(path).stat().st_mtime) / 86400)
        except OSError:
            continue
        rows.append({"real": path, "path": "~/" + Path(path).relative_to(HOME).as_posix(),
                     "mb": int(size) // 2 ** 20, "days": days})
    return sorted(rows, key=lambda r: -r["mb"])[:40]


def left_out_by_ai(path):
    """True when leaving this folder out could cost the user their data or settings."""
    p = Path(path)
    # the kept folder itself, or a folder holding one: its subfolders (a cache in ~/.config) may go
    return p in KEEP or any(p in k.parents for k in KEEP)


def cmd_ai(a):
    if shutil.which("claude") is None:
        raise Failure("claude is not installed")
    rows = home_listing()
    if not rows:
        raise Failure("no folder in your home is big enough to judge")
    cfg = load_config()
    listing = "\n".join(f"{r['path']}\t{r['mb']} MB\t{r['days']} d" for r in rows)
    already = ", ".join(e for e in cfg["excludes"] if e.startswith(str(HOME))) or "nothing"
    DIR.mkdir(parents=True, exist_ok=True)
    try:
        run = subprocess.run(["claude", "-p", AI_PROMPT + f"\nAlready left out: {already}\n\nThe list:\n" + listing,
                              "--model", a.model, "--output-format", "json", "--tools", "",
                              "--no-session-persistence", "--max-budget-usd", "0.50"],
                             capture_output=True, text=True, timeout=240, cwd=str(DIR), env=claude_env())
    except subprocess.TimeoutExpired:
        raise Failure("Claude took too long (4 min)") from None
    try:
        reply = json.loads(run.stdout)
        text = reply.get("result", "") if isinstance(reply, dict) else ""
        if reply.get("is_error"):
            raise Failure("Claude: " + (text or "error")[:200])
        text = re.sub(r"^```(?:json)?|```$", "", text.strip(), flags=re.M).strip()
        wanted = json.loads(text[text.index("{"):text.rindex("}") + 1])["suggestions"]
    except (ValueError, KeyError, TypeError, AttributeError):
        raise Failure("Claude's answer was not the list: " + (run.stderr or run.stdout)[:200]) from None
    by_shown = {r["path"]: r for r in rows}
    suggestions = []
    for item in wanted:
        row = by_shown.get(item.get("path") if isinstance(item, dict) else None)
        # only what was in the list, never something the AI invented, never what must stay
        if not row or row["real"] in cfg["excludes"] or left_out_by_ai(row["real"]):
            continue
        suggestions.append({"path": row["real"], "shown": row["path"], "mb": row["mb"], "days": row["days"],
                            "why": str(item.get("why", ""))[:90],
                            "risk": "medium" if item.get("risk") == "medium" else "low"})
    return {"ok": True, "suggestions": suggestions, "message": f"{len(suggestions)} suggestions from Claude"}


def guide_lines(cfg):
    """How to get everything back after a breakage: the same text in the app and in the terminal."""
    repo = cfg["repo"] or "<REPOSITORY>"
    home = str(HOME)
    return [
        "You need: the drive with the backups, mounted; the repository password (from your password",
        "manager, or the file below if this computer still works); restic (pacman -S restic).",
        "",
        f"Repository: {repo}",
        f"Password file here: {PASSWORD}",
        "",
        "1. See what is there",
        f"   restic -r {repo} snapshots",
        "   restic asks for the password. Tags: auto = timer, manual = Back up now, root = system files.",
        "",
        "2. Your files, into an empty folder (nothing on the system is touched)",
        f"   restic -r {repo} restore latest --target /mnt/restore --include {home}",
        f"   They land in /mnt/restore{home}/. Copy what you need back: cp -a /mnt/restore{home}/<folder> ~/",
        "",
        "3. Packages, services and groups",
        f"   restic -r {repo} dump latest {home}/.local/state/dotfiles/packages.txt > packages.txt",
        "   Its '# native' part installs from the repositories: pacman -S --needed - < list (the part between",
        "   the headers, one name per line). '# services' are enabled with systemctl enable; '# groups' are",
        "   added with usermod -aG. On a working system, the Backups app does all of it: Snapshots, Packages.",
        "   AUR names ('# foreign') are built with yay by hand, one by one.",
        "",
        "4. System files, read only as root",
        f"   restic -r {repo} snapshots --tag root",
        f"   restic -r {repo} restore <id of that snapshot> --target /mnt/restore-root",
        "   Look first, then copy as root: /etc/NetworkManager/system-connections (Wi-Fi), /etc/shadow",
        "   (logins), /var/lib/bluetooth (Bluetooth pairings), /etc/ssh host keys if this is a server.",
        "   /etc/fstab holds disk UUIDs: check them against lsblk -f before you use it.",
        "",
        "5. Dotfiles",
        "   ~/.dotfiles came back with step 2. Then: cd ~/.dotfiles && ./install.py setup",
        "",
        "Check the repository now and then: restic -r REPO check (the app: Overview › Check).",
    ]


def cmd_guide(a):
    lines = guide_lines(load_config())
    return {"ok": True, "lines": lines, "text": "\n".join(lines), "message": "How to restore"}


def cmd_pick(a):
    """Asks the shell's Files window for a folder (its picker, the one the file-chooser portal uses) and
    waits for the answer. The folder is taken as it is: restic adds its own folders inside it."""
    ident = secrets.token_hex(16)
    request = {"id": ident, "mode": "open", "directory": True, "multiple": False,
               "title": "Pick the folder for the backups", "folder": a.start or str(HOME)}
    try:
        proc = subprocess.run(["qs", "-c", "shell", "ipc", "call", "files", "choose", json.dumps(request)],
                              capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        raise Failure("qs is not running: the shell is needed to pick a folder") from None
    if proc.returncode != 0:
        raise Failure("the Files window could not open: " + (proc.stderr.strip() or "is the shell running?")[:160])
    runtime = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
    answer = Path(runtime, "files-portal", ident + ".json")
    deadline = time.monotonic() + 15 * 60
    while time.monotonic() < deadline:
        if answer.exists():
            try:
                reply = json.loads(answer.read_text())
            finally:
                answer.unlink(missing_ok=True)
            paths = reply.get("paths") or []
            if reply.get("response") != 0 or not paths:
                raise Failure("no folder picked")
            return {"ok": True, "path": paths[0], "message": f"Picked {paths[0]}"}
        time.sleep(0.5)
    raise Failure("no folder picked in 15 minutes")


def cmd_size(a):
    """How big the backups are: what the repository takes on disk, and what the newest snapshot restores to."""
    if not configured():
        raise Failure("no repository yet")
    on_disk = json.loads(restic(["stats", "--mode", "raw-data", "--json"]).stdout or "{}").get("total_size", 0)
    restore = json.loads(restic(["stats", "--mode", "restore-size", "--json", "latest"], check=False).stdout or "{}").get("total_size", 0)
    return {"ok": True, "on_disk": on_disk, "restore": restore,
            "message": f"{size_text(on_disk)} on disk, the newest snapshot restores to {size_text(restore)}"}


def cmd_sizes(a):
    """The size of each folder or file directly under PATH in a snapshot (the whole subtree of a folder)."""
    snap_arg(a.snapshot)
    path = (a.path or "/").rstrip("/") or "/"
    proc = restic(["ls", "--json", "--recursive", a.snapshot, path])
    prefix = path + "/" if path != "/" else "/"
    sizes = {}
    for node in json_lines(proc.stdout):
        p = node.get("path", "") if node.get("struct_type") == "node" else ""
        if not p.startswith(prefix) or p == path:
            continue
        child = prefix + p[len(prefix):].split("/")[0]
        sizes[child] = sizes.get(child, 0) + int(node.get("size") or 0)
    return {"ok": True, "path": path, "sizes": sizes, "message": f"{len(sizes)} sizes"}


def cmd_root_plan(a):
    """The root pass (for RootService): /etc and the Bluetooth pairings, read as root, into the
    same repository. Root writes its files as root, so the repository is given back to the user."""
    cfg = load_config()
    repo = require_repo(cfg)
    require_password()
    need_restic()
    user = getpass.getuser()
    command = shlex.join(["restic", "-r", repo, "--password-file", str(PASSWORD), "backup", "--tag", "root",
                          "--exclude-caches", *ROOT_PATHS])
    give_back = f"chown -R {shlex.quote(user)} {shlex.quote(repo)} 2>/dev/null || true" if is_local(repo) else ""
    script = f"{command}\nrc=$?\n{give_back}\n[ \"$rc\" -eq 0 ] || [ \"$rc\" -eq 3 ]\n"
    steps = [{"label": "Back up the root-only files", "what": " ".join(ROOT_PATHS) + ", as root", "command": command}]
    return {"ok": True, "steps": steps, "script": script, "message": "Asks for your password"}


def cmd_aur(a):
    names = snapshot_lists(a.snapshot)["foreign"]
    if not names:
        raise Failure("the snapshot names no AUR packages")
    return {"ok": True, "aur": names, "message": f"{len(names)} AUR packages"}


def cmd_forget(a):
    for s in a.snapshot:
        snap_arg(s)
    with locked():
        restic(["forget", *a.snapshot, *(["--prune"] if a.prune else [])])
    return {"ok": True, "message": f"Forgot {len(a.snapshot)} snapshot{'s' if len(a.snapshot) > 1 else ''}"}


def cmd_verify(a):
    with locked():
        proc = restic(["check", *(["--read-data"] if a.deep else [])], check=False)
    if proc.returncode != 0:
        raise Failure(explain(proc))
    return {"ok": True, "message": "The repository is intact" + (" (every pack read)" if a.deep else "")}


def units(mode, time_text):
    when = f"*-*-* {time_text}:00" if mode == "daily" else f"Mon *-*-* {time_text}:00"
    service = ("[Unit]\nDescription=Dotfiles backup (restic)\n\n[Service]\nType=oneshot\n"
               f"ExecStart={sys.executable} {SCRIPT} run --auto\nNice=19\nIOSchedulingClass=idle\n")
    timer = ("[Unit]\nDescription=Dotfiles backup schedule\n\n[Timer]\n"
             f"OnCalendar={when}\nPersistent=true\n\n[Install]\nWantedBy=timers.target\n")
    return service, timer


def systemctl(*args, check=True):
    try:
        proc = subprocess.run(["systemctl", "--user", *args], capture_output=True, text=True)
    except OSError as e:
        raise Failure(str(e)) from None
    if check and proc.returncode != 0:
        raise Failure((proc.stderr.strip() or "systemctl failed")[:200])


def cmd_schedule(a):
    # a timed run without a repository (or its password) would fail every night: refuse it here
    if a.mode != "off" and not configured():
        raise Failure("set a repository in Setup first: a timed run needs it")
    cfg = load_config()
    cfg["schedule"] = {"mode": a.mode, "time": a.time or cfg["schedule"]["time"]}
    timer = UNIT_DIR / f"{UNIT}.timer"
    service = UNIT_DIR / f"{UNIT}.service"
    # the config is saved once systemd took the change: a failed one leaves the old schedule
    if a.mode == "off":
        systemctl("disable", "--now", f"{UNIT}.timer", check=False)
        for f in (timer, service):
            f.unlink(missing_ok=True)
        systemctl("daemon-reload", check=False)
        save_config(cfg)
        return {"ok": True, "config": cfg, "message": "Scheduled backups are off"}
    unit_service, unit_timer = units(a.mode, cfg["schedule"]["time"])
    UNIT_DIR.mkdir(parents=True, exist_ok=True)
    service.write_text(unit_service)
    timer.write_text(unit_timer)
    systemctl("daemon-reload")
    systemctl("enable", "--now", f"{UNIT}.timer")
    save_config(cfg)
    return {"ok": True, "config": cfg, "message": f"Backups {a.mode} at {cfg['schedule']['time']}"}


# ---- command line ----

def build_parser():
    p = argparse.ArgumentParser(prog="backup.py", description="Encrypted backups of home, /etc and the package list (restic).")
    p.add_argument("--json", action="store_true", help="the shell's form: progress lines, then one JSON reply")
    sub = p.add_subparsers(dest="cmd", required=True)

    sub.add_parser("status", help="what is set up and the last run").set_defaults(func=cmd_status)

    s = sub.add_parser("init", help="create the repository and its password file")
    s.add_argument("--repo", help="a folder (on a mounted drive) or a restic repository")
    s.set_defaults(func=cmd_init)

    sub.add_parser("password", help="print the repository's password").set_defaults(func=cmd_password)

    s = sub.add_parser("config", help="show the settings, or change some")
    s.add_argument("action", nargs="?", choices=["show", "set"], default="show")
    s.add_argument("value", nargs="?", help="with set: a JSON object to merge in")
    s.set_defaults(func=cmd_config)

    s = sub.add_parser("run", help="back up now")
    s.add_argument("--auto", action="store_true", help="from the timer: tag auto, notify when done")
    s.set_defaults(func=cmd_run)

    sub.add_parser("snapshots", help="every snapshot").set_defaults(func=cmd_snapshots)

    s = sub.add_parser("ls", help="the folders and files of a snapshot")
    s.add_argument("snapshot")
    s.add_argument("path", nargs="?", help="a folder in the snapshot (default: its top)")
    s.set_defaults(func=cmd_ls)

    s = sub.add_parser("restore", help="copy from a snapshot into a new folder")
    s.add_argument("snapshot")
    s.add_argument("--include", action="append", default=[], metavar="PATH", help="only this path (repeat)")
    s.add_argument("--target", help="the folder (default: ~/Restore/restore-<time>)")
    s.set_defaults(func=cmd_restore)

    s = sub.add_parser("packages", help="the steps to reinstall the snapshot's packages")
    s.add_argument("snapshot")
    s.set_defaults(func=cmd_packages)

    s = sub.add_parser("aur", help="the AUR packages a snapshot lists (built by yay, in a terminal)")
    s.add_argument("snapshot")
    s.set_defaults(func=cmd_aur)

    s = sub.add_parser("ai", help="Claude suggests what to leave out (needs the claude command)")
    s.add_argument("--model", default="haiku")
    s.set_defaults(func=cmd_ai)

    sub.add_parser("guide", help="how to restore after a breakage").set_defaults(func=cmd_guide)

    sub.add_parser("size", help="how big the backups are").set_defaults(func=cmd_size)

    s = sub.add_parser("sizes", help="the size of each folder or file under PATH in a snapshot")
    s.add_argument("snapshot")
    s.add_argument("path", nargs="?")
    s.set_defaults(func=cmd_sizes)

    s = sub.add_parser("pick", help="pick any folder in the Files window (the repository goes there)")
    s.add_argument("--start", help="the folder the picker opens in (default: home)")
    s.set_defaults(func=cmd_pick)

    sub.add_parser("root-plan", help="the root pass: /etc and Bluetooth, as root (for the shell's root panel)").set_defaults(func=cmd_root_plan)

    s = sub.add_parser("forget", help="remove snapshots")
    s.add_argument("snapshot", nargs="+")
    s.add_argument("--prune", action="store_true", help="also free the space now")
    s.set_defaults(func=cmd_forget)

    s = sub.add_parser("verify", help="check the repository")
    s.add_argument("--deep", action="store_true", help="read every data pack (slow)")
    s.set_defaults(func=cmd_verify)

    s = sub.add_parser("schedule", help="run backups by a systemd user timer")
    s.add_argument("mode", choices=["off", "daily", "weekly"])
    s.add_argument("--time", help="HH:MM (default: the saved time)")
    s.set_defaults(func=cmd_schedule)
    return p


def main(argv=None):
    global JSON
    a = build_parser().parse_args(argv)
    JSON = a.json
    try:
        reply(a.func(a))
    except Failure as e:
        reply({"ok": False, "error": str(e)})


if __name__ == "__main__":
    main()
