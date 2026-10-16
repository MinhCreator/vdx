"""dotfiles installer — this machine's profile (.machine.toml, local, not in git).

  [hardware]   what `machine detect` found; rewritten by every detect
  [override]   the same keys, set by hand where detection is wrong; kept

Other tables (features, input, ...) are kept as they are by `detect`; comments
are not (the file is written by the installer).
"""

from __future__ import annotations

import json
import tomllib

from . import detect
from .paths import ROOT
from .ui import added, bold, confirm, dim, err, heading, note, ok, warn

PROFILE = ROOT / ".machine.toml"
VERSION = 1
# outputs come and go with cables: a change there is no reason to re-detect
VOLATILE = {"monitors"}


# --------------------------------------------------------------------------- file

def load() -> dict | None:
    """The saved profile; None when there is none or it can't be read."""
    if not PROFILE.is_file():
        return None
    try:
        return tomllib.loads(PROFILE.read_text())
    except tomllib.TOMLDecodeError as e:
        err(f"{PROFILE.name}: {e}")
        return None


def hardware(profile: dict | None = None) -> dict:
    """The saved hardware with the overrides on top; detected when nothing is saved."""
    profile = load() if profile is None else profile
    if not profile:
        return detect.hardware()
    return {**profile.get("hardware", {}), **profile.get("override", {})}


def value(v) -> str:
    """A TOML value: the profile holds strings, numbers, booleans, lists and flat tables."""
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return str(v)
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=False)        # a JSON string is a valid TOML basic string
    if isinstance(v, list):
        return "[" + ", ".join(value(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{ " + ", ".join(f"{k} = {value(x)}" for k, x in v.items()) + " }"
    raise TypeError(f"no TOML for {type(v).__name__}")


def dumps(profile: dict) -> str:
    lines = ["# dotfiles — this machine's profile (local, not in git): `./install.py machine`",
             "# [hardware] is rewritten by `machine detect`; fix wrong values in [override].",
             f"version = {VERSION}"]
    for table, keys in profile.items():
        if table == "version" or not isinstance(keys, dict):
            continue
        lines += ["", f"[{table}]"]
        for k, v in keys.items():
            if isinstance(v, list) and v and isinstance(v[0], dict):
                lines += [f"{k} = ["] + [f"  {value(x)}," for x in v] + ["]"]
            else:
                lines.append(f"{k} = {value(v)}")
    return "\n".join(lines) + "\n"


def save(profile: dict) -> None:
    PROFILE.write_text(dumps(profile))


def changes(old: dict, new: dict) -> list[str]:
    """Keys of [hardware] that differ, volatile ones left out."""
    return [k for k in sorted(set(old) | set(new)) if k not in VOLATILE and old.get(k) != new.get(k)]


# --------------------------------------------------------------------------- display

def describe(hw: dict) -> str:
    """One line: model · kind · GPUs."""
    t = detect.traits(hw)
    model = hw.get("product") or hw.get("board") or "unknown machine"
    kind = "laptop" if t["laptop"] else hw.get("chassis", "unknown")
    return f"{model} · {kind} · {' + '.join(t['gpu']) or 'no GPU'}"


def show(hw: dict, overrides: dict) -> None:
    t = detect.traits(hw)

    def row(label: str, text: str) -> None:
        mark = bold("*") if label in overrides else " "
        print(f"  {label:16s}{mark} {text}")

    row("machine", f"{hw.get('vendor', '')} {hw.get('product', '')}".strip() or "unknown")
    row("board", hw.get("board") or "--")
    row("chassis", hw.get("chassis", "unknown"))
    row("cpu", hw.get("cpu", "unknown"))
    for i, g in enumerate(hw.get("gpus", [])):
        row("gpus" if i == 0 else "", f"{g['vendor']} {dim(g['pci'] + ' · ' + (g['driver'] or 'no driver') + (' · boot' if g['boot'] else ''))}")
    if hw.get("dgpu_off"):
        row("", dim("a dGPU switched off (asus-wmi): not seen"))
    row("battery", hw.get("battery") or "--")
    row("charge_limit", "yes" if hw.get("charge_limit") else "no")
    row("platform_profile", "yes" if hw.get("platform_profile") else "no")
    row("backlight", hw.get("backlight") or "--")
    row("wifi", hw.get("wifi") or "--")
    row("bluetooth", "yes" if hw.get("bluetooth") else "no")
    for i, c in enumerate(hw.get("codecs", [])):
        row("codecs" if i == 0 else "", c["name"] + " " + dim(f"hwC{c['card']}D{c['index']}"))
    for i, m in enumerate(hw.get("monitors", [])):
        row("monitors" if i == 0 else "", f"{m['name']} {dim(m['mode'] + ' · ' + m['card'] + (' · internal' if m['internal'] else ''))}")
    print()
    row("gpu", " + ".join(t["gpu"]) + (" (hybrid)" if t["hybrid"] else ""))
    row("laptop", "yes" if t["laptop"] else "no")
    row("asus", "yes" if t["asus"] else "no")
    row("quirks", ", ".join(t["quirks"]) or "--")
    if overrides:
        note("* set in [override]")


def show_environment() -> None:
    env = detect.environment()
    print()
    print(f"  {'distro':17s} {env['distro']}" + ("" if env["distro"] == "arch" else f" {dim('(only Arch is supported)')}"))
    print(f"  {'hyprland':17s} {env['hyprland'] or '--'}")
    print(f"  {'aur helper':17s} {env['aur_helper'] or '--'}")
    print(f"  {'login shell':17s} {env['shell']}")
    print(f"  {'groups':17s} {' '.join(env['groups']) or '--'}")


# --------------------------------------------------------------------------- commands

def cmd_machine(args) -> int:
    action = getattr(args, "m_action", None) or "show"
    profile = load()
    if profile is None and PROFILE.is_file():
        note(f"fix {PROFILE.name} or remove it: it is not rewritten while unreadable")
        return 1
    found = detect.hardware()

    if action == "show":
        heading(f"Machine {dim('(' + (PROFILE.name if profile else 'detected, not saved') + ')')}")
        show(hardware(profile) if profile else found, (profile or {}).get("override", {}))
        show_environment()
        if not profile:
            print()
            note("`./install.py machine detect` saves it")
        elif drift := changes(profile.get("hardware", {}), found):
            print()
            warn(f"the hardware has changed since the last detect: {', '.join(drift)}")
            note("`./install.py machine detect` updates the profile")
        return 0

    # detect
    heading("Detecting the machine")
    show(found, {})
    if found["dgpu_off"]:
        print()
        warn("the dGPU is switched off (supergfxctl Integrated), so it isn't detected:")
        note("switch to Hybrid and reboot before `machine detect`, or list it in [override] gpus")
    old = (profile or {}).get("hardware")
    if old is not None:
        drift = changes(old, found)
        if not drift and old.get("monitors") == found.get("monitors"):
            print()
            ok(f"{PROFILE.name} is up to date")
            return 0
        if drift:
            print()
            warn(f"changed: {', '.join(drift)}")
        if not confirm(f"Rewrite [hardware] in {PROFILE.name}?", args):
            return 1
    save({**(profile or {}), "version": VERSION, "hardware": found})
    print()
    added(f"{PROFILE.name}")
    return 0
