"""dotfiles installer — components (components.toml): what is on, what it brings, what owns a file.

The selection lives in .machine.toml ([components] selected). Without one,
every component is on except hardware whose `auto` doesn't hold here, so a
machine that never chose behaves as before components existed.
"""

from __future__ import annotations

import tomllib

from . import detect, machine
from .paths import ROOT

CATALOG = ROOT / "components.toml"
GROUPS = ["core", "desktop", "terminal", "editor", "apps", "music", "network", "ai", "personal", "hardware"]
LISTS = {"requires", "suggests", "auto", "pacman", "aur", "links", "submodules", "modules",
         "system", "services", "user_services", "user_units", "masks", "secrets"}
FIELDS = LISTS | {"group", "about", "default", "hint"}


# --------------------------------------------------------------------------- catalog

def load() -> dict[str, dict]:
    """name -> component, in file order, every list field present."""
    raw = tomllib.loads(CATALOG.read_text())
    return {name: {**{k: [] for k in LISTS}, "default": True, **c} for name, c in raw.items()}


def holds(term: str, hw: dict) -> bool:
    """One `auto` term against the hardware; `!term` holds when term doesn't."""
    if term.startswith("!"):
        return not holds(term[1:], hw)
    t = detect.traits(hw)
    kind, _, arg = term.partition(":")
    if kind == "gpu":
        return arg in t["gpu"]
    if kind == "quirk":
        return arg in t["quirks"]
    return bool(t.get(kind))


def detected(c: dict, hw: dict) -> bool:
    return all(holds(term, hw) for term in c["auto"])


# --------------------------------------------------------------------------- selection

def closure(names: set[str], cat: dict) -> set[str]:
    """names, core and everything they require (unknown names dropped)."""
    out = {n for n, c in cat.items() if c["group"] == "core"}
    todo = [n for n in names if n in cat]
    while todo:
        n = todo.pop()
        if n not in out:
            out.add(n)
            todo += [r for r in cat[n]["requires"] if r in cat]
    return out | {n for n in names if n in cat}


def everything(cat: dict, hw: dict) -> set[str]:
    """The selection of a machine that never chose: all but undetected hardware."""
    return {n for n, c in cat.items() if c["group"] != "hardware" or detected(c, hw)}


def defaults(cat: dict, hw: dict) -> set[str]:
    """A new machine's ticks: `default` ones, hardware by detection, plus suggestions."""
    picked = {n for n, c in cat.items()
              if (detected(c, hw) if c["group"] == "hardware" else c["default"])}
    for n in list(picked):
        picked |= set(cat[n]["suggests"])
    return closure(picked, cat)


def saved(profile: dict | None) -> list[str] | None:
    """The selection written in the profile; None when it has never chosen."""
    sel = (profile or {}).get("components", {}).get("selected")
    return list(sel) if isinstance(sel, list) else None


def selected(profile: dict | None = None, cat: dict | None = None) -> set[str]:
    """The components that are on here."""
    profile = machine.load() if profile is None else profile
    cat = load() if cat is None else cat
    names = saved(profile)
    if names is None:
        return closure(everything(cat, machine.hardware(profile)), cat)
    return closure(set(names), cat)


def required_by(name: str, names: set[str], cat: dict) -> list[str]:
    """Selected components that can't stay without `name`."""
    return sorted(n for n in names if n != name and name in cat[n]["requires"])


# --------------------------------------------------------------------------- what they bring

def claims(cat: dict) -> list[tuple[str, str]]:
    """(path, component), longest path first: the first prefix that matches owns a file."""
    pairs = [(p.rstrip("/"), n) for n, c in cat.items() for p in c["links"]]
    return sorted(pairs, key=lambda pc: -len(pc[0]))


def owner(key: str, table: list[tuple[str, str]]) -> str | None:
    """The component owning a file: `<pkg>/<rel>` for packages, `home/<name>` for ~."""
    for path, name in table:
        if key == path or key.startswith(path + "/"):
            return name
    return None


def unique(names: set[str], cat: dict, field: str) -> list[str]:
    """A list field over the given components, catalog order, no repeats."""
    return list(dict.fromkeys(x for n, c in cat.items() if n in names for x in c[field]))


# --------------------------------------------------------------------------- check

def problems(cat: dict | None = None) -> list[str]:
    """The catalog's own mistakes (what's on the disk is checked by check.py)."""
    try:
        cat = load() if cat is None else cat
    except (OSError, tomllib.TOMLDecodeError) as e:
        return [f"components.toml: {e}"]
    out = []
    for n, c in cat.items():
        where = f"components.toml: [{n}]"
        out += [f"{where}: unknown field {k!r}" for k in sorted(set(c) - FIELDS)]
        if c.get("group") not in GROUPS:
            out.append(f"{where}: group {c.get('group')!r} is not one of {', '.join(GROUPS)}")
        if not c.get("about"):
            out.append(f"{where}: no about")
        for k in LISTS:
            if not isinstance(c[k], list) or not all(isinstance(x, str) for x in c[k]):
                out.append(f"{where}: {k} is not a list of strings")
            elif len(set(c[k])) != len(c[k]):
                out.append(f"{where}: {k} lists a name twice")
        for k in ("requires", "suggests"):
            out += [f"{where}: {k} {r!r}: no such component" for r in c[k] if r not in cat]
        if c["auto"] and c.get("group") != "hardware":
            out.append(f"{where}: auto is for hardware only")
        if c.get("group") == "hardware" and not c["auto"]:
            out.append(f"{where}: hardware needs auto")
        for term in c["auto"]:
            kind, _, arg = term.removeprefix("!").partition(":")
            if kind not in ("gpu", "quirk", "hybrid", "laptop", "asus"):
                out.append(f"{where}: auto {term!r}: unknown term")
            elif kind == "quirk" and arg not in detect.QUIRKS:
                out.append(f"{where}: auto {term!r}: no such quirk in installer/detect.py")
        out += [f"{where}: pacman and aur both list {p}" for p in sorted(set(c["pacman"]) & set(c["aur"]))]
    # requires must not loop
    for n in cat:
        seen, todo = set(), list(cat[n]["requires"])
        while todo:
            r = todo.pop()
            if r == n:
                out.append(f"components.toml: [{n}] requires itself (through {', '.join(sorted(seen)) or 'itself'})")
                break
            if r in cat and r not in seen:
                seen.add(r)
                todo += cat[r]["requires"]
    # one path, one owner
    paths: dict[str, str] = {}
    for n, c in cat.items():
        for p in c["links"]:
            if p in paths:
                out.append(f"components.toml: links {p!r} is in both [{paths[p]}] and [{n}]")
            paths[p] = n
    return out
