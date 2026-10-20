#!/usr/bin/env python3
"""files — the file manager's filesystem (apps/files): listings, search, the
places, and the operations: new folder / file, rename, copy, move, trash,
delete, restore. Trash follows the freedesktop spec in the home trash; a file
on another device goes through `gio trash` (that device's own trash) and does
not show in the trash list.

    list <dir> [counts]              {"path", "entries": [entry, ...]}; counts: a folder's "count" of items
    recent [limit]                   the files opened lately (recently-used.xbel), the newest first, "visited"
    entries <path...>                an entry per path that still exists (the starred ones)
    search <dir> <query> [limit seconds]   entries whose name contains the query (walk, capped)
    places                           {"places": [{name, path}, ...]} from user-dirs.dirs
    mkdir <path>                     a new folder
    touch <path>                     a new empty file
    rename <path> <name>             {"path": new path}
    paste copy|move <dir> <src...>   {"done", "errors"}; a name taken gets " (2)"
    trash <path...>                  {"done", "errors", "moved": [{"from", "id"}]}; id None off-device
    duplicates <dir>                 {"entries": [...], "groups": n}: files with the same content, group by group
    stat <path>                      {"info": {…}} for the properties panel
    delete <path...>                 permanent, {"done", "errors"}
    trash-list                       entries of the home trash, with "original" and "deleted"
    restore <id...>                  {"done", "errors"}; id = a trash entry's "id"
    purge <id...>                    permanent from the trash
    empty-trash                      {"ok": true}
    preview <path> [lines]           {"text"}: the first lines of a text file ("" when binary)
    rename-all <json>                [[path, new name], ...] in one go, {"done", "errors"}
    devices                          {"devices": [{name, path, mount, removable, size, fstype, total, free}, ...]}
    volumes                          {"volumes": [{name, path, mount, mounts, fstype, kind, total, free, size}]}
                                     the "This computer" page: real filesystems once each, unmounted drives last
    mount <device> / unmount <device>   udisks2 (/dev/…); mount: {"mount": where it went}
    answer <id> <json>               the portal's answer, read by files_portal.py

    thumb <path> <size>              a PNG picture of a video's or a PDF's first page, cached: {"path"}

entry: {name, path, kind: dir|image|video|audio|text|pdf|archive|file, size, mtime, link}
"""
import grp, hashlib, json, mimetypes, os, pwd, re, shutil, sys, time, urllib.parse
from datetime import datetime

from backend import out, fail, run

HOME = os.path.expanduser("~")
DATA = os.environ.get("XDG_DATA_HOME") or os.path.join(HOME, ".local", "share")
CONFIG = os.environ.get("XDG_CONFIG_HOME") or os.path.join(HOME, ".config")
TRASH = os.path.join(DATA, "Trash")
SEARCH_LIMIT = 300
SEARCH_SECONDS = 5
PREVIEW_BYTES = 8192
PREVIEW_LINES = 40
RUNTIME = os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}"
ARCHIVES = ("zip", "x-tar", "gzip", "x-bzip2", "x-xz", "x-7z-compressed", "x-rar",
            "zstd", "x-zstd", "x-compressed-tar", "x-lzma")


def kind_of(path):
    if os.path.isdir(path):
        return "dir"
    major, _, minor = (mimetypes.guess_type(path)[0] or "/").partition("/")
    if major in ("image", "video", "audio"):
        return major
    if major == "text" or minor in ("json", "xml", "x-shellscript", "x-python", "javascript"):
        return "text"
    if minor == "pdf":
        return "pdf"
    if minor in ARCHIVES:
        return "archive"
    return "file"


def entry(path):
    try:
        st = os.lstat(path)
    except OSError:
        return None
    return {
        "name": os.path.basename(path), "path": path, "kind": kind_of(path),
        "size": 0 if os.path.isdir(path) else st.st_size,
        "mtime": int(st.st_mtime), "link": os.path.islink(path),
    }


def valid_name(name):
    return name not in ("", ".", "..") and "/" not in name


def check_name(name):
    if not valid_name(name):
        fail("a name can't be empty, '.', '..' or hold a '/'")


def unique(dest):
    """dest, or the first free `name (n).ext` beside it"""
    if not os.path.lexists(dest):
        return dest
    base, ext = os.path.splitext(dest)
    n = 2
    while os.path.lexists(f"{base} ({n}){ext}"):
        n += 1
    return f"{base} ({n}){ext}"


def info_of(name):
    return os.path.join(TRASH, "info", name + ".trashinfo")


def read_info(path):
    original, deleted = "", ""
    try:
        with open(path, encoding="utf-8") as f:
            for line in f:
                if line.startswith("Path="):
                    original = urllib.parse.unquote(line[5:].strip())
                elif line.startswith("DeletionDate="):
                    deleted = line[13:].strip()
    except OSError:
        pass
    return original, deleted


def trash_here(path):
    files = os.path.join(TRASH, "files")
    os.makedirs(files, exist_ok=True)
    os.makedirs(os.path.join(TRASH, "info"), exist_ok=True)
    dest = unique(os.path.join(files, os.path.basename(path)))
    stamp = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    # the info file first: a trash entry without one can't be restored
    with open(info_of(os.path.basename(dest)), "x", encoding="utf-8") as f:       # never over an orphan record
        f.write(f"[Trash Info]\nPath={urllib.parse.quote(path)}\nDeletionDate={stamp}\n")
    shutil.move(path, dest)
    return os.path.basename(dest)


def progress(i, total, name):
    """one line per item while it runs (the shell's job line); the reply is the last line"""
    print(json.dumps({"progress": i, "of": total, "name": os.path.basename(name)}), flush=True)


def each(names, action):
    """run action(name) for each, collecting the failures: {"ok", "done", "errors"}"""
    done, errors = 0, []
    for i, name in enumerate(names, 1):
        progress(i, len(names), name)
        try:
            if action(name) is not False:
                done += 1
        except OSError as e:
            errors.append(f"{os.path.basename(name)}: {e.strerror or e}")
    out({"ok": True, "done": done, "errors": errors})


def item_count(path):
    try:
        with os.scandir(path) as it:
            return sum(1 for _ in it)
    except OSError:
        return -1


def cmd_list(path, counts=False):
    path = os.path.abspath(os.path.expanduser(path))
    if not os.path.isdir(path):
        fail(f"not a folder: {path}")
    try:
        names = os.listdir(path)
    except PermissionError:
        fail("permission denied")
    entries = [e for e in (entry(os.path.join(path, n)) for n in names) if e]
    if counts:
        for e in entries:
            if e["kind"] == "dir":
                e["count"] = item_count(e["path"])
    out({"ok": True, "path": path, "entries": entries})


def recent_from(text, limit):
    """The local files of a recently-used.xbel, the newest visit first, each once."""
    import xml.etree.ElementTree as ET
    try:
        root = ET.fromstring(text)
    except ET.ParseError:
        return []
    seen = {}
    for b in root.iter("bookmark"):
        href = b.get("href", "")
        if not href.startswith("file://"):
            continue
        path = urllib.parse.unquote(href[7:])
        when = b.get("visited") or b.get("modified") or ""
        if when > seen.get(path, ""):
            seen[path] = when
    found = []
    for path, when in sorted(seen.items(), key=lambda kv: kv[1], reverse=True):
        e = entry(path)
        if e and e["kind"] != "dir":
            e["visited"] = when
            found.append(e)
            if len(found) >= limit:
                break
    return found


def cmd_recent(limit=50):
    try:
        with open(os.path.join(DATA, "recently-used.xbel"), encoding="utf-8") as f:
            text = f.read()
    except OSError:
        text = "<xbel/>"
    out({"ok": True, "entries": recent_from(text, limit)})


def cmd_entries(paths):
    out({"ok": True, "entries": [e for e in (entry(p) for p in paths) if e]})


def cmd_search(root, query, limit=SEARCH_LIMIT, seconds=SEARCH_SECONDS):
    root = os.path.abspath(os.path.expanduser(root))
    q = query.lower()
    dotted = q.startswith(".")                     # hidden names are searched only for a dotted query
    found, started = [], time.monotonic()
    truncated = False
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if dotted or not d.startswith(".")]
        for n in dirnames + filenames:
            if not dotted and n.startswith("."):
                continue
            if q in n.lower():
                e = entry(os.path.join(dirpath, n))
                if e:
                    found.append(e)
                if len(found) >= limit:
                    truncated = True
                    break
        if truncated or time.monotonic() - started > seconds:
            truncated = True
            break
    out({"ok": True, "path": root, "entries": found, "truncated": truncated})


def cmd_places():
    places = [{"name": "Home", "path": HOME}]
    shown = {"XDG_DESKTOP_DIR", "XDG_DOCUMENTS_DIR", "XDG_DOWNLOAD_DIR", "XDG_MUSIC_DIR",
             "XDG_PICTURES_DIR", "XDG_VIDEOS_DIR"}
    try:
        with open(os.path.join(CONFIG, "user-dirs.dirs"), encoding="utf-8") as f:
            for line in f:
                key, _, value = line.strip().partition("=")
                path = value.strip('"').replace("$HOME", HOME)
                if key in shown and path != HOME and os.path.isdir(path):
                    places.append({"name": key[4:-4].capitalize(), "path": path})
    except OSError:
        pass
    places.append({"name": "Root", "path": "/"})
    out({"ok": True, "places": places})


def cmd_mkdir(path):
    path = os.path.abspath(os.path.expanduser(path))
    check_name(os.path.basename(path))
    try:
        os.mkdir(path)
    except FileExistsError:
        fail("already exists")
    except OSError as e:
        fail(e.strerror or str(e))
    out({"ok": True, "path": path})


def cmd_touch(path):
    path = os.path.abspath(os.path.expanduser(path))
    check_name(os.path.basename(path))
    try:
        open(path, "x").close()
    except FileExistsError:
        fail("already exists")
    except OSError as e:
        fail(e.strerror or str(e))
    out({"ok": True, "path": path})


def cmd_rename(path, name):
    path = os.path.abspath(os.path.expanduser(path))
    check_name(name)
    target = os.path.join(os.path.dirname(path), name)
    if os.path.lexists(target) and target != path:
        fail("already exists")
    try:
        os.rename(path, target)
    except OSError as e:
        fail(e.strerror or str(e))
    out({"ok": True, "path": target})


def cmd_paste(mode, dest, srcs):
    if mode not in ("copy", "move"):
        fail("paste takes copy or move")
    dest = os.path.abspath(os.path.expanduser(dest))
    if not os.path.isdir(dest):
        fail(f"not a folder: {dest}")
    real_dest = os.path.realpath(dest)
    done, errors, made = 0, [], []
    for i, src in enumerate(srcs, 1):
        progress(i, len(srcs), src)
        src = os.path.abspath(src)
        name = os.path.basename(src)
        if mode == "move" and os.path.dirname(src) == dest:
            continue                                   # cut and pasted back in place
        real_src = os.path.realpath(src)
        if os.path.isdir(real_src) and (real_dest == real_src or real_dest.startswith(real_src + os.sep)):
            errors.append(f"{name}: a folder can't go inside itself")
            continue
        try:
            target = unique(os.path.join(dest, name))
            if mode == "move":
                shutil.move(src, target)
            elif os.path.isdir(src) and not os.path.islink(src):
                shutil.copytree(src, target, symlinks=True)
            else:
                shutil.copy2(src, target, follow_symlinks=False)
            done += 1
            made.append(target)
        except OSError as e:
            errors.append(f"{name}: {e.strerror or e}")
    out({"ok": True, "done": done, "errors": errors, "made": made})


def cmd_trash(paths):
    home_dev = os.stat(HOME).st_dev
    done, errors, moved = 0, [], []
    for i, p in enumerate(paths, 1):
        progress(i, len(paths), p)
        p = os.path.abspath(os.path.expanduser(p))
        try:
            if not os.path.lexists(p):
                raise FileNotFoundError(2, "no such file")
            if os.lstat(p).st_dev == home_dev:
                moved.append({"from": p, "id": trash_here(p)})
            else:
                r = run(["gio", "trash", p])       # another device: its own trash, no id to undo with
                if r is None or r.returncode != 0:
                    raise OSError(0, (r.stderr.strip() if r else "gio trash failed") or "gio trash failed")
                moved.append({"from": p, "id": None})
            done += 1
        except OSError as e:
            errors.append(f"{os.path.basename(p)}: {e.strerror or e}")
    out({"ok": True, "done": done, "errors": errors, "moved": moved})


def cmd_stat(path):
    path = os.path.abspath(os.path.expanduser(path))
    try:
        st = os.lstat(path)
    except OSError as e:
        fail(e.strerror or str(e))
    try:
        owner = pwd.getpwuid(st.st_uid).pw_name
        group = grp.getgrgid(st.st_gid).gr_name
    except KeyError:
        owner, group = str(st.st_uid), str(st.st_gid)
    items = len(os.listdir(path)) if os.path.isdir(path) and not os.path.islink(path) else None
    target = os.readlink(path) if os.path.islink(path) else ""
    out({"ok": True, "info": {
        "name": os.path.basename(path), "path": path, "kind": kind_of(path), "size": st.st_size,
        "mtime": int(st.st_mtime), "mode": oct(st.st_mode & 0o7777)[2:], "owner": owner, "group": group,
        "mime": mimetypes.guess_type(path)[0] or "", "items": items, "link": target,
    }})


def cmd_delete(paths):
    def action(p):
        p = os.path.abspath(os.path.expanduser(p))
        if os.path.isdir(p) and not os.path.islink(p):
            shutil.rmtree(p)
        else:
            os.remove(p)
    each(paths, action)


def cmd_trash_list():
    files = os.path.join(TRASH, "files")
    entries = []
    try:
        names = os.listdir(files)
    except FileNotFoundError:
        names = []
    for n in names:
        e = entry(os.path.join(files, n))
        if not e:
            continue
        e["id"] = n
        e["original"], e["deleted"] = read_info(info_of(n))
        entries.append(e)
    out({"ok": True, "entries": entries})


def cmd_restore(ids):
    files = os.path.join(TRASH, "files")

    def action(n):
        if not valid_name(n):
            raise OSError(0, "not a trash entry")
        original, _ = read_info(info_of(n))
        if not original:
            raise OSError(0, "no record of where it was")
        os.makedirs(os.path.dirname(original), exist_ok=True)
        shutil.move(os.path.join(files, n), unique(original))
        os.remove(info_of(n))
    each(ids, action)


def cmd_purge(ids):
    def action(n):
        if not valid_name(n):
            raise OSError(0, "not a trash entry")
        p = os.path.join(TRASH, "files", n)
        if os.path.isdir(p) and not os.path.islink(p):
            shutil.rmtree(p)
        else:
            os.remove(p)
        if os.path.lexists(info_of(n)):
            os.remove(info_of(n))
    each(ids, action)


def cmd_empty_trash():
    for sub in ("files", "info"):
        shutil.rmtree(os.path.join(TRASH, sub), ignore_errors=True)
    out({"ok": True})


def cmd_preview(path, lines=PREVIEW_LINES):
    path = os.path.abspath(os.path.expanduser(path))
    try:
        with open(path, "rb") as f:
            data = f.read(PREVIEW_BYTES)
    except OSError as e:
        fail(e.strerror or str(e))
    if b"\0" in data:
        out({"ok": True, "text": ""})
    text = data.decode("utf-8", "replace").splitlines()[:lines]
    out({"ok": True, "text": "\n".join(text)})


LSBLK = ["lsblk", "-J", "-o", "NAME,PATH,LABEL,MOUNTPOINT,RM,HOTPLUG,SIZE,TYPE,FSTYPE"]
# filesystems that are not storage: never a row of the "This computer" page
PSEUDO_FS = {"autofs", "binfmt_misc", "bpf", "cgroup", "cgroup2", "configfs", "debugfs", "devpts",
             "devtmpfs", "efivarfs", "fusectl", "hugetlbfs", "mqueue", "nsfs", "overlay", "proc",
             "pstore", "ramfs", "rpc_pipefs", "securityfs", "squashfs", "sysfs", "tmpfs", "tracefs",
             "fuse.gvfsd-fuse", "fuse.portal", "fuse.snapfuse"}
NETWORK_FS = {"nfs", "nfs4", "cifs", "smb3", "fuse.sshfs"}


def flag(v):
    return str(v).lower() in ("1", "true")


def block_nodes(nodes, removable=False):
    """lsblk's partitions and crypt devices with a fstype, each as (node, removable): a removable
    drive's flag reaches its partitions"""
    for d in nodes:
        removable_here = removable or flag(d.get("rm")) or flag(d.get("hotplug"))
        if d.get("type") in ("part", "crypt") and d.get("fstype") and d.get("fstype") != "swap":
            yield d, removable_here
        yield from block_nodes(d.get("children") or [], removable_here)


def read_lsblk():
    r = run(LSBLK)
    if r is None or r.returncode != 0:
        fail("lsblk failed")
    try:
        return json.loads(r.stdout).get("blockdevices", [])
    except ValueError:
        fail("could not read lsblk")


def devices_from(nodes, usage):
    """The sidebar's devices: removable drives (plugged in, mounted or not) and anything udisks mounted
    for the user. nodes: block_nodes(); usage(path) -> (total, free). "removable" tells the USB section
    from the rest."""
    devices = []
    for d, removable in nodes:
        mount = d.get("mountpoint") or ""
        if removable or mount.startswith(("/run/media/", "/media/")):
            total, free = usage(mount) if mount else (0, 0)
            devices.append({"name": d.get("label") or os.path.basename(d.get("path") or ""),
                            "path": d.get("path") or "", "mount": mount, "removable": removable,
                            "size": d.get("size") or "", "fstype": d.get("fstype"),
                            "total": total, "free": free})
    return devices


def cmd_devices():
    out({"ok": True, "devices": devices_from(block_nodes(read_lsblk()), disk_space)})


def volumes_from(mounts, nodes, usage):
    """The "This computer" rows. mounts: findmnt's list [{target, source, fstype}]; nodes: block_nodes();
    usage(path) -> (total, free). A source mounted several times (btrfs subvolumes, bind mounts) is one
    row whose mount is its shortest target; the others are listed in "mounts". Removable drives that are
    not mounted yet come last, with mount "" (a click mounts them)."""
    info = {d.get("path"): (d, removable) for d, removable in nodes}
    rows, by_source = [], {}
    for m in mounts:
        fs, source, target = m.get("fstype") or "", m.get("source") or "", m.get("target") or ""
        if fs in PSEUDO_FS or (fs.startswith("fuse.") and fs not in NETWORK_FS):
            continue
        if source in by_source:
            by_source[source]["mounts"].append(target)
            continue
        node, removable = info.get(source, ({}, False))
        kind = "network" if fs in NETWORK_FS else "removable" if removable else "disk"
        label = node.get("label") or ""
        by_source[source] = {"path": source, "fstype": fs, "kind": kind, "label": label, "mounts": [target]}
        rows.append(by_source[source])
    result = []
    for r in rows:
        r["mounts"].sort(key=lambda p: (len(p), p))
        mount = r["mounts"][0]
        total, free = usage(mount)
        name = r["label"] or ("Root" if mount == "/" else os.path.basename(mount.rstrip("/")) or r["path"])
        result.append({"name": name, "path": r["path"], "mount": mount, "mounts": r["mounts"],
                       "fstype": r["fstype"], "kind": r["kind"], "total": total, "free": free, "size": ""})
    mounted = {r["path"] for r in rows}
    for node, removable in nodes:
        if removable and not node.get("mountpoint") and node.get("path") not in mounted:
            result.append({"name": node.get("label") or os.path.basename(node.get("path") or ""),
                           "path": node.get("path") or "", "mount": "", "mounts": [],
                           "fstype": node.get("fstype"), "kind": "removable", "total": 0, "free": 0,
                           "size": node.get("size") or ""})
    return result


def disk_space(path):
    try:
        usage = shutil.disk_usage(path)
        return usage.total, usage.free
    except OSError:
        return 0, 0


def cmd_volumes():
    r = run(["findmnt", "-Jl", "-o", "TARGET,SOURCE,FSTYPE"])
    if r is None or r.returncode != 0:
        fail("findmnt failed")
    try:
        mounts = json.loads(r.stdout).get("filesystems", [])
    except ValueError:
        fail("could not read findmnt")
    out({"ok": True, "volumes": volumes_from(mounts, block_nodes(read_lsblk()), disk_space)})


def udisks(action, dev):
    if not dev.startswith("/dev/"):
        fail("a device is a /dev/ path")
    r = run(["udisksctl", action, "-b", dev, "--no-user-interaction"], timeout=60)
    if r is None:
        fail("udisksctl is not installed")
    if r.returncode != 0:
        fail(r.stderr.strip() or f"{action} failed")
    return r.stdout.strip()


def cmd_mount(dev):
    msg = udisks("mount", dev)                       # "Mounted /dev/sdb1 at /run/media/…."
    m = re.search(r" at (.+)\.$", msg)
    out({"ok": True, "mount": m.group(1) if m else ""})


def cmd_unmount(dev):
    udisks("unmount", dev)
    out({"ok": True})


THUMB_DIR = os.path.join(os.environ.get("XDG_CACHE_HOME") or os.path.join(HOME, ".cache"), "quickshell-files", "thumbs")


def cmd_thumb(path, size):
    """a video frame (ffmpegthumbnailer) or a PDF's first page (pdftoppm), cached by path, size and mtime"""
    path = os.path.abspath(os.path.expanduser(path))
    try:
        mtime = int(os.stat(path).st_mtime)
    except OSError as e:
        fail(e.strerror or str(e))
    kind = kind_of(path)
    if kind not in ("video", "pdf"):
        fail("no thumbnail for this kind")
    tool = "ffmpegthumbnailer" if kind == "video" else "pdftoppm"
    if shutil.which(tool) is None:
        fail(f"install {'ffmpegthumbnailer' if kind == 'video' else 'poppler'} for the {kind} preview")
    os.makedirs(THUMB_DIR, exist_ok=True)
    key = hashlib.sha1(f"{path}|{mtime}|{size}".encode()).hexdigest()
    target = os.path.join(THUMB_DIR, key + ".png")
    if os.path.exists(target):
        out({"ok": True, "path": target})
    if kind == "video":
        r = run(["ffmpegthumbnailer", "-i", path, "-o", target, "-s", str(size), "-f", "-q", "7"], timeout=30)
    else:
        base = target[:-4]
        r = run(["pdftoppm", "-png", "-singlefile", "-f", "1", "-l", "1", "-scale-to", str(size), path, base], timeout=30)
    if r is None or r.returncode != 0 or not os.path.exists(target):
        fail(f"{tool} could not make the picture")
    out({"ok": True, "path": target})


DUP_LIMIT_FILES = 20000
DUP_SECONDS = 15


def file_hash(path):
    h = hashlib.sha1()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def cmd_duplicates(root):
    """files of one size are read and hashed: the same hash is one group, the biggest groups first"""
    root = os.path.abspath(os.path.expanduser(root))
    started, seen = time.monotonic(), 0
    by_size = {}
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if not d.startswith(".")]
        for n in filenames:
            if n.startswith(".") or seen >= DUP_LIMIT_FILES or time.monotonic() - started > DUP_SECONDS:
                continue
            path = os.path.join(dirpath, n)
            if os.path.islink(path) or not os.path.isfile(path):
                continue
            seen += 1
            try:
                size = os.path.getsize(path)
            except OSError:
                continue
            if size > 0:
                by_size.setdefault(size, []).append(path)
    by_hash = {}
    for size, paths in by_size.items():
        if len(paths) < 2:
            continue
        for path in paths:
            try:
                by_hash.setdefault((size, file_hash(path)), []).append(path)
            except OSError:
                pass
    groups = sorted((g for g in by_hash.values() if len(g) > 1), key=lambda g: (-len(g), -os.path.getsize(g[0])))
    entries = []
    for gi, group in enumerate(groups):
        for path in sorted(group):
            e = entry(path)
            if e:
                e["group"] = gi
                entries.append(e)
    out({"ok": True, "path": root, "entries": entries, "groups": len(groups)})


def cmd_rename_all(payload):
    try:
        pairs = json.loads(payload)
    except ValueError:
        fail("rename-all takes JSON")
    # two steps, so a name taken by another file of the batch is free when it's needed
    # every name is checked before the first file moves: a bad one stops the batch, nothing is left staged
    for _, name in pairs:
        if not valid_name(name):
            fail(f"a name can't be empty, '.', '..' or hold a '/': {name!r}")
    staged, errors, done = [], [], 0
    for i, (src, name) in enumerate(pairs):
        src = os.path.abspath(src)
        try:
            tmp = os.path.join(os.path.dirname(src), f".rename-{os.getpid()}-{i}")
            os.rename(src, tmp)
            staged.append((tmp, os.path.join(os.path.dirname(src), name), os.path.basename(src)))
        except OSError as e:
            errors.append(f"{os.path.basename(src)}: {e.strerror or e}")
    for tmp, target, old in staged:
        try:
            if os.path.lexists(target):
                raise FileExistsError(17, "already exists")
            os.rename(tmp, target)
            done += 1
        except OSError as e:
            errors.append(f"{old}: {e.strerror or e}")
            try:
                os.rename(tmp, os.path.join(os.path.dirname(tmp), old))   # put back what could not be named
            except OSError as back:
                errors.append(f"{old}: left as {os.path.basename(tmp)} ({back.strerror or back})")
    out({"ok": True, "done": done, "errors": errors})


def cmd_answer(ident, payload):
    if not re.fullmatch(r"[0-9a-f]{32}", ident):
        fail("bad request id")
    try:
        json.loads(payload)
    except ValueError:
        fail("the answer is not JSON")
    folder = os.path.join(RUNTIME, "files-portal")
    os.makedirs(folder, mode=0o700, exist_ok=True)
    target = os.path.join(folder, ident + ".json")
    with open(target + ".tmp", "w", encoding="utf-8") as f:
        f.write(payload)
    os.replace(target + ".tmp", target)              # the portal polls for the whole file
    out({"ok": True})


def main(argv):
    usage = "usage: files.py list|search|places|mkdir|touch|rename|paste|trash|delete|trash-list|restore|purge|empty-trash …"
    if not argv:
        fail(usage)
    cmd, args = argv[0], argv[1:]
    if cmd == "list" and len(args) in (1, 2):
        cmd_list(args[0], args[1:] == ["counts"])
    elif cmd == "recent" and len(args) in (0, 1):
        cmd_recent(*(int(a) for a in args))
    elif cmd == "entries" and args:
        cmd_entries(args)
    elif cmd == "search" and len(args) in (2, 4):
        cmd_search(args[0], args[1], *(int(a) for a in args[2:]))
    elif cmd == "places" and not args:
        cmd_places()
    elif cmd in ("mkdir", "touch") and len(args) == 1:
        (cmd_mkdir if cmd == "mkdir" else cmd_touch)(args[0])
    elif cmd == "rename" and len(args) == 2:
        cmd_rename(args[0], args[1])
    elif cmd == "paste" and len(args) >= 3:
        cmd_paste(args[0], args[1], args[2:])
    elif cmd == "trash" and args:
        cmd_trash(args)
    elif cmd == "delete" and args:
        cmd_delete(args)
    elif cmd == "trash-list" and not args:
        cmd_trash_list()
    elif cmd == "restore" and args:
        cmd_restore(args)
    elif cmd == "purge" and args:
        cmd_purge(args)
    elif cmd == "empty-trash" and not args:
        cmd_empty_trash()
    elif cmd == "preview" and len(args) in (1, 2):
        cmd_preview(args[0], int(args[1]) if len(args) == 2 else PREVIEW_LINES)
    elif cmd == "duplicates" and len(args) == 1:
        cmd_duplicates(args[0])
    elif cmd == "thumb" and len(args) == 2:
        cmd_thumb(args[0], int(args[1]))
    elif cmd == "rename-all" and len(args) == 1:
        cmd_rename_all(args[0])
    elif cmd == "devices" and not args:
        cmd_devices()
    elif cmd == "volumes" and not args:
        cmd_volumes()
    elif cmd in ("mount", "unmount") and len(args) == 1:
        (cmd_mount if cmd == "mount" else cmd_unmount)(args[0])
    elif cmd == "stat" and len(args) == 1:
        cmd_stat(args[0])
    elif cmd == "answer" and len(args) == 2:
        cmd_answer(args[0], args[1])
    else:
        fail(usage)


if __name__ == "__main__":
    main(sys.argv[1:])
