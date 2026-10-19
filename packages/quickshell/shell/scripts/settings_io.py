#!/usr/bin/env python3
"""The shell's options as one file (About › Settings). One JSON object on stdout.

    settings_io.py export <file> [--dir D]               {"ok", "files": [...]}
    settings_io.py import <file> [--dir D] [--pid P]     {"ok", "files": [...]}
    settings_io.py reset [--dir D] [--pid P]             {"ok", "files": [...]}

The bundle is {"kind": KIND, "version", "files": {name: data}} for the option
files settings_migrate.py knows (settings, modules, layout); the Windows page
(Hyprland's) and the theme are not in it. Import migrates each file to the
current version; import and reset keep every file they replace as <file>.bak
(reset first writes the whole set to settings-before-reset.json beside them).
A bad bundle changes nothing ({"ok": false, "error"}, exit 1).

The running shell keeps its options in memory and writes them back, so with
--pid (the shell's, Quickshell.processId) it is stopped before the files are
written and started again through supervise.sh (as About › Restart does)."""
import json, os, signal, subprocess, sys, time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import settings_migrate as sm  # noqa: E402

KIND = "dotfiles-shell-settings"


def bundle(folder: Path) -> dict:
    files = {}
    for name in sm.FILES:
        try:
            data = json.loads((folder / name).read_text())
        except (OSError, ValueError):
            continue
        if isinstance(data, dict):
            files[name] = data
    return {"kind": KIND, "version": sm.VERSION, "files": files}


def read_bundle(path: Path) -> dict:
    """The files of a bundle, migrated; ValueError when it is not one."""
    try:
        data = json.loads(path.read_text())
    except OSError as e:
        raise ValueError(f"cannot read {path}: {e.strerror}")
    except ValueError:
        raise ValueError(f"{path} is not JSON")
    if not isinstance(data, dict) or data.get("kind") != KIND or not isinstance(data.get("files"), dict):
        raise ValueError(f"{path} is not a shell settings file")
    files = {n: d for n, d in data["files"].items() if n in sm.FILES and isinstance(d, dict)}
    if not files:
        raise ValueError(f"{path} has no options")
    return {n: sm.migrate(n, d) for n, d in files.items()}


def write(path: Path, data) -> None:
    tmp = path.with_name(path.name + ".tmp")
    tmp.write_text(json.dumps(data, indent=4) + "\n")
    tmp.replace(path)


def replace_files(folder: Path, files: dict) -> list:
    """Each file → <file>.bak, then the new content ({"version"} alone: defaults)."""
    for name, data in files.items():
        old = folder / name
        if old.exists():
            old.replace(old.with_name(name + ".bak"))
        write(old, data)
    return list(files)


def stop_shell(pid: int) -> None:
    """TERM the shell (its supervisor ends with it) and wait until it is gone."""
    try:
        os.kill(pid, signal.SIGTERM)
        for _ in range(100):
            os.kill(pid, 0)
            time.sleep(0.05)
    except ProcessLookupError:
        pass


def start_shell() -> None:
    supervisor = Path(__file__).resolve().parent / "supervise.sh"
    subprocess.Popen([str(supervisor)], start_new_session=True,
                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def main(argv: list) -> int:
    args = argv[1:]
    folder, pid = sm.state_dir(), 0
    if "--dir" in args:
        i = args.index("--dir")
        folder = Path(args[i + 1])
        del args[i:i + 2]
    if "--pid" in args:
        i = args.index("--pid")
        pid = int(args[i + 1])
        del args[i:i + 2]
    cmd = args[0] if args else ""
    try:
        if cmd == "export" and len(args) == 2:
            data = bundle(folder)
            write(Path(args[1]).expanduser(), data)
            files = list(data["files"])
        elif cmd == "import" and len(args) == 2:
            new = read_bundle(Path(args[1]).expanduser())
            if pid:
                stop_shell(pid)
            files = replace_files(folder, new)
        elif cmd == "reset" and len(args) == 1:
            write(folder / "settings-before-reset.json", bundle(folder))
            if pid:
                stop_shell(pid)
            files = replace_files(folder, {n: {"version": sm.VERSION} for n in sm.FILES})
        else:
            print(__doc__.split("\n\n")[1], file=sys.stderr)
            return 2
    except ValueError as e:
        print(json.dumps({"ok": False, "error": str(e)}))
        return 1
    if pid:
        start_shell()
    print(json.dumps({"ok": True, "files": files}))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
