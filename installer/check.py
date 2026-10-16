"""dotfiles installer — `check`: the repo itself (links, syntax, themes, deps, the shell, the repo)."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

from .links import link_problems
from .model import build_entries, read_list
from .paths import PKG, ROOT, THEME
from .ui import err, heading, ok, warn

# `check` looks at the repo, not at the machine: links, the syntax of every
# tracked file, generated themes, package lists, the shell's registry and
# icons, ignored files and trailing whitespace. Each group returns its
# problems as "path: what"; a tool that is not installed skips its part.

SHELL = PKG / "quickshell" / "shell"


def tracked() -> list[Path]:
    """Files git tracks here (submodules are checked in their own repositories)."""
    names = subprocess.run(["git", "-C", str(ROOT), "ls-files", "-z"], capture_output=True, text=True).stdout
    return [ROOT / n for n in names.split("\0") if n and (ROOT / n).is_file() and not (ROOT / n).is_symlink()]


def rel(p: Path) -> str:
    return str(p.relative_to(ROOT))


def strip_jsonc(text: str) -> str:
    """JSON with // and /* */ comments -> plain JSON (strings are left alone)."""
    out, i, n = [], 0, len(text)
    while i < n:
        if text[i] == '"':
            j = i + 1
            while j < n and text[j] != '"':
                j += 2 if text[j] == "\\" else 1
            out.append(text[i:j + 1])
            i = j + 1
        elif text.startswith("//", i):
            i = text.find("\n", i) if "\n" in text[i:] else n
        elif text.startswith("/*", i):
            i = text.find("*/", i) + 2 if "*/" in text[i:] else n
        else:
            out.append(text[i])
            i += 1
    return "".join(out)


def language(f: Path) -> str:
    """What a tracked file is checked as; "" for nothing."""
    if f.suffix in (".py", ".lua", ".json", ".jsonc", ".toml", ".qml", ".sh"):
        return f.suffix[1:]
    if rel(f).startswith("packages/zsh/") or f.name == ".zshenv":
        return "zsh"
    try:
        first = f.read_text().split("\n", 1)[0]
    except (UnicodeDecodeError, OSError):
        return ""
    if first.startswith("#!"):
        return "py" if "python" in first else "sh" if re.search(r"\b(ba)?sh\b", first) else ""
    return "xml" if first.startswith("<?xml") else ""


def tool_errors(command: list[str], files: list[Path]) -> list[str]:
    """Run a checker on each file; its first output line names the problem."""
    out = []
    for f in files:
        r = subprocess.run(command + [str(f)], capture_output=True, text=True)
        if r.returncode != 0:
            msg = (r.stderr or r.stdout).strip().splitlines()
            line = msg[0].replace(str(f), rel(f)) if msg else "failed"
            out.append(line if rel(f) in line else f"{rel(f)}: {line}")
    return out


def qmllint() -> str | None:
    return shutil.which("qmllint") or next((p for p in ("/usr/lib/qt6/bin/qmllint",) if Path(p).is_file()), None)


def syntax_problems() -> list[str]:
    import tomllib
    import xml.etree.ElementTree as ET
    by: dict[str, list[Path]] = {}
    for f in tracked():
        by.setdefault(language(f), []).append(f)
    out = []
    for f in by.get("py", []):
        try:
            compile(f.read_text(), rel(f), "exec")
        except SyntaxError as e:
            out.append(f"{rel(f)}:{e.lineno}: {e.msg}")
    for f in by.get("json", []) + by.get("jsonc", []):
        try:
            json.loads(strip_jsonc(f.read_text()))
        except ValueError as e:
            out.append(f"{rel(f)}: {e}")
    for f in by.get("toml", []):
        try:
            tomllib.loads(f.read_text())
        except tomllib.TOMLDecodeError as e:
            out.append(f"{rel(f)}: {e}")
    for f in by.get("xml", []):
        try:
            ET.parse(f)
        except ET.ParseError as e:
            out.append(f"{rel(f)}: {e}")
    out += tool_errors(["bash", "-n"], by.get("sh", []))
    for lang, command in (("zsh", ["zsh", "-n"]), ("lua", ["luac", "-p"])):
        if not by.get(lang):
            continue
        if shutil.which(command[0]):
            out += tool_errors(command, by[lang])
        else:
            warn(f"{command[0]} not found: {lang} files not checked")
    lint = qmllint()
    if lint and by.get("qml"):
        # syntax only: the rest of qmllint's warnings are about types it can't
        # see (Quickshell's), not mistakes
        r = subprocess.run([lint, "--json", "-", *map(str, by["qml"])], capture_output=True, text=True)
        try:
            for f in json.loads(r.stdout)["files"]:
                for w in f["warnings"]:
                    if w.get("id") == "syntax":
                        out.append(f"{rel(Path(f['filename']))}:{w.get('line')}: {w['message']}")
        except (ValueError, KeyError):
            out.append(f"qmllint: unreadable output ({r.stderr.strip()[:80]})")
    elif by.get("qml"):
        warn("qmllint not found (qt6-declarative): QML not checked")
    return out


def theme_problems() -> list[str]:
    script = THEME / "mktheme.py"
    if not script.is_file():
        return []
    r = subprocess.run([sys.executable, str(script), "--check"], capture_output=True, text=True)
    stale = [f"{line}: out of date — run themes/mktheme.py" for line in r.stdout.splitlines() if line]
    return stale + ([r.stderr.strip()] if r.returncode and not stale else [])


def deps_problems() -> list[str]:
    repo, aur = read_list("pacman.txt"), read_list("aur.txt")
    out = []
    for name, names in (("pacman.txt", repo), ("aur.txt", aur)):
        out += [f"deps/{name}: {p} listed twice" for p in sorted({p for p in names if names.count(p) > 1})]
    out += [f"deps: {p} is in both lists" for p in sorted(set(repo) & set(aur))]
    if shutil.which("pacman"):
        env = {**os.environ, "LC_ALL": "C"}
        r = subprocess.run(["pacman", "-Si", *sorted(set(repo))], capture_output=True, text=True, env=env)
        out += [f"deps/pacman.txt: {p} is in no repository"
                for p in re.findall(r"package '([^']+)' was not found", r.stderr)]
        known = set(subprocess.run(["pacman", "-Slq"], capture_output=True, text=True).stdout.split())
        out += [f"deps/aur.txt: {p} is in a repository — move it to pacman.txt" for p in aur if p in known]
    return out


def qml_strings(expr: str) -> list[str]:
    """The string literals of a QML expression, less those it compares against."""
    return [m.group(1) for m in re.finditer(r'"([^"]*)"', expr)
            if not re.search(r"[=!]==?\s*$", expr[:m.start()]) and re.fullmatch(r"[a-z0-9][a-z0-9-]*", m.group(1))]


def icon_uses(path: Path, text: str) -> list[tuple[str, int]]:
    """(icon name, line) written out in a QML file: `icon` / `iconOn` / `iconOff`
    values anywhere, `name` inside a KitIcon."""
    uses = []
    stack: list[str] = []
    for no, line in enumerate(text.splitlines(), 1):
        for m in re.finditer(r"\b(icon(?:On|Off)?)\s*:\s*([^,;}\n]+)", line):
            uses += [(s, no) for s in qml_strings(m.group(2))]
        m = re.match(r"\s*name\s*:\s*(.+)", line)
        if m and stack and stack[-1] == "KitIcon":
            uses += [(s, no) for s in qml_strings(m.group(1))]
        # the object each `{` opens: `KitIcon {` -> KitIcon, anything else -> ?
        code = re.sub(r'"[^"]*"', '""', line.split("//", 1)[0])
        for m in re.finditer(r"([A-Za-z_]\w*)?\s*([{}])", code):
            if m.group(2) == "{":
                stack.append(m.group(1) if m.group(1) and m.group(1)[0].isupper() else "?")
            elif stack:
                stack.pop()
    return uses


def shell_problems() -> list[str]:
    if not SHELL.is_dir():
        return []
    out = []
    srel = lambda p: str(p.relative_to(SHELL))
    qml = {p: p.read_text() for p in sorted(SHELL.rglob("*.qml"))}
    # icons: every outline icon has its solid twin, every name written out exists
    icons = SHELL / "kit" / "icons"
    outline = {p.stem for p in icons.glob("*.svg")}
    solid = {p.stem for p in (icons / "solid").glob("*.svg")}
    out += [f"kit/icons/{n}.svg: no solid/ twin" for n in sorted(outline - solid)]
    out += [f"kit/icons/solid/{n}.svg: no outline twin" for n in sorted(solid - outline)]
    registry = SHELL / "apps" / "apps.json"
    apps = json.loads(registry.read_text()) if registry.is_file() else []
    uses = [(srel(p), n, no) for p, text in qml.items() for n, no in icon_uses(p, text)]
    uses += [("apps/apps.json", a["icon"], 0) for a in apps if "icon" in a]
    out += [f"{f}:{no}: no icon {n!r} in kit/icons" for f, n, no in uses if n not in outline]
    # imports
    for p, text in qml.items():
        for m in re.finditer(r"^import qs\.([\w.]+)", text, re.M):
            if not (SHELL / m.group(1).replace(".", "/")).is_dir():
                out.append(f"{srel(p)}: import qs.{m.group(1)}: no such folder")
    # scripts the QML runs
    for p, text in qml.items():
        for m in re.finditer(r'scriptsDir \+ "/([\w.-]+)"', text):
            if not (SHELL / "scripts" / m.group(1)).is_file():
                out.append(f"{srel(p)}: scripts/{m.group(1)}: no such script")
    # the bar's registry: a folder, a settings page and a Component per module
    layout, bar = SHELL / "bar" / "BarLayout.qml", SHELL / "bar" / "Bar.qml"
    modules = re.findall(r'\{ id: "(\w+)",[^}]*\}', qml.get(layout, ""))
    components = set(re.findall(r"Component\s*\{\s*id:\s*(\w+)", qml.get(bar, "")))
    for entry in re.findall(r'\{ id: "\w+",[^}]*\}', qml.get(layout, "")):
        mid = re.search(r'id: "(\w+)"', entry).group(1)
        settings = re.search(r'settings: "([\w.]+)"', entry)
        if settings and not (SHELL / "modules" / mid / settings.group(1)).is_file():
            out.append(f"bar/BarLayout.qml: {mid}: no modules/{mid}/{settings.group(1)}")
        if mid not in components:
            out.append(f"bar/Bar.qml: no Component for module {mid}")
    # the apps' registry: files, modules, IPC targets and binds it names
    targets = set(re.findall(r'(?:target|ipcTarget):\s*"([\w-]+)"', "\n".join(qml.values())))
    keybinds = PKG / "hypr" / "components" / "keybinds.lua"
    binds = keybinds.read_text() if keybinds.is_file() else ""
    for a in apps:
        aid = a.get("id", "?")
        for key in ("settings", "moduleSettings"):
            if key in a and not (SHELL / a[key]).is_file():
                out.append(f"apps/apps.json: {aid}: no {a[key]}")
        if "module" in a and a["module"] not in modules:
            out.append(f"apps/apps.json: {aid}: no bar module {a['module']!r}")
        if a.get("ipc") and a["ipc"] not in targets:
            out.append(f"apps/apps.json: {aid}: no IPC target {a['ipc']!r}")
        if a.get("bind") and f'"{a["bind"]}"' not in binds:
            out.append(f"apps/apps.json: {aid}: no bind {a['bind']!r} in hypr/components/keybinds.lua")
    # IPC targets written out twice answer only once
    found = re.findall(r'(?:target|ipcTarget):\s*"([\w-]+)"', "\n".join(t for p, t in qml.items() if "IpcHandler" in t or "ipcTarget" in t))
    out += [f"IPC target {t!r} is declared twice" for t in sorted({t for t in found if found.count(t) > 1})]
    return out


def repo_problems() -> list[str]:
    out = []
    ignored = subprocess.run(["git", "-C", str(ROOT), "ls-files", "-ci", "--exclude-standard"],
                             capture_output=True, text=True).stdout.split()
    out += [f"{f}: tracked but ignored (.gitignore) — a secret?" for f in ignored]
    for f in tracked():
        if f.suffix == ".md":                       # two trailing spaces are a line break there
            continue
        try:
            lines = f.read_text().splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        bad = [i for i, line in enumerate(lines, 1) if line != line.rstrip()]
        if bad:
            out.append(f"{rel(f)}:{bad[0]}: trailing whitespace" + (f" (+{len(bad) - 1} more)" if len(bad) > 1 else ""))
    return out


CHECKS = {
    "links": lambda: link_problems(build_entries()),
    "syntax": syntax_problems,
    "themes": theme_problems,
    "deps": deps_problems,
    "shell": shell_problems,
    "repo": repo_problems,
}


def cmd_check(args) -> int:
    unknown = [g for g in args.groups if g not in CHECKS]
    if unknown:
        err(f"no such check: {', '.join(unknown)} (have: {', '.join(CHECKS)})")
        return 2
    heading("Checking the repo")
    total = 0
    for name in args.groups or CHECKS:
        problems = CHECKS[name]()
        total += len(problems)
        if not problems:
            ok(name)
            continue
        err(f"{name}: {len(problems)} problem(s)")
        for line in problems:
            print(f"      {line}")
    return 1 if total else 0
