"""dotfiles installer — this machine's Hyprland parts, written from .machine.toml.

The repo's hypr config is the same everywhere; what differs per machine goes
to ~/.config/hypr/machine/<name>.lua (real files, not links), which the config
loads when present (components/machine.lua). From [hypr] of the profile:

  gpu_env      "nvidia" | "none"     default: nvidia when it's the only GPU
  layouts      "us,ru"               keyboard layouts; options: layout_options
  monitors     [{output, mode, position, scale}, ...]
  workspaces   {"<output>" = "1-8", ...}   the first of each is its default

`link` keeps the files in step; one the profile no longer asks for is removed.
"""

from __future__ import annotations

import json
import re
from pathlib import Path

from . import components, detect, machine
from .paths import TGT
from .ui import added, removed

DIR = TGT / "hypr" / "machine"
MARK = "written by ./install.py from .machine.toml"

NVIDIA_ENV = [
    ("LIBVA_DRIVER_NAME", "nvidia"),
    ("GBM_BACKEND", "nvidia-drm"),
    ("__GLX_VENDOR_LIBRARY_NAME", "nvidia"),
    ("__GL_GSYNC_ALLOWED", "1"),
    ("__GL_VRR_ALLOWED", "1"),
    ("__GL_SYNC_TO_VBLANK", "1"),
    ("__GL_MaxFramesAllowed", "1"),
]


def lua(v) -> str:
    """A Lua literal for a profile value."""
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, float)):
        return repr(v)
    return json.dumps(str(v), ensure_ascii=False)   # a JSON string is a valid Lua string


def header(what: str, link: str = "") -> list[str]:
    return [f"-- Hyprland — this machine's {what} ({MARK}; edit that, not this)"] + ([f"-- {link}"] if link else []) + [""]


def workspace_numbers(spec: str) -> list[int]:
    """"1-8" -> 1..8, "9,10" -> 9, 10; ValueError on anything else."""
    out = []
    for part in str(spec).replace(" ", "").split(","):
        m = re.fullmatch(r"(\d+)(?:-(\d+))?", part)
        if not m:
            raise ValueError(f"workspaces: bad range {part!r}")
        a, b = int(m.group(1)), int(m.group(2) or m.group(1))
        out += range(a, b + 1)
    return out


def gpu_env(profile: dict, hw: dict) -> str:
    cfg = profile.get("hypr", {})
    if "gpu_env" in cfg:
        return cfg["gpu_env"]
    t = detect.traits(hw)
    return "nvidia" if "nvidia" in t["gpu"] and not t["hybrid"] else "none"


def render(profile: dict, hw: dict | None = None) -> dict[str, str | None]:
    """name -> file text, None for a file this machine doesn't get."""
    hw = machine.hardware(profile) if hw is None else hw
    cfg = profile.get("hypr", {})
    files: dict[str, str | None] = {}

    env = gpu_env(profile, hw)
    files["gpu"] = "\n".join(header("GPU environment", "https://wiki.hypr.land/Nvidia/")
                             + [f"hl.env({lua(k)}, {lua(v)})" for k, v in NVIDIA_ENV]) + "\n" if env == "nvidia" else None

    if cfg.get("layouts"):
        opts = {"kb_layout": cfg["layouts"]}
        if cfg.get("layout_options"):
            opts["kb_options"] = cfg["layout_options"]
        body = ",\n".join(f"\t\t{k} = {lua(v)}" for k, v in opts.items())
        files["input"] = "\n".join(header("keyboard layouts")) + f"\nhl.config({{\n\tinput = {{\n{body},\n\t}},\n}})\n"
    else:
        files["input"] = None

    if cfg.get("monitors"):
        lines = header("monitors and workspaces", "https://wiki.hypr.land/Configuring/Basics/Monitors/")
        for m in cfg["monitors"]:
            lines += ["hl.monitor({"] + [f"\t{k} = {lua(m[k])}," for k in ("output", "mode", "position", "scale") if k in m] + ["})", ""]
        for output, spec in cfg.get("workspaces", {}).items():
            for i, n in enumerate(workspace_numbers(spec)):
                extra = ", default = true" if i == 0 else ""
                lines.append(f"hl.workspace_rule({{ workspace = {lua(str(n))}, monitor = {lua(output)}{extra} }})")
        files["monitors"] = "\n".join(lines).rstrip("\n") + "\n"
    else:
        files["monitors"] = None
    return files


def problems(profile: dict) -> list[str]:
    """Mistakes in [hypr] that would write a broken config."""
    cfg = profile.get("hypr", {})
    out = []
    if cfg.get("gpu_env", "none") not in ("nvidia", "none"):
        out.append(f"[hypr] gpu_env {cfg['gpu_env']!r}: nvidia or none")
    outputs = set()
    for i, m in enumerate(cfg.get("monitors", [])):
        if not isinstance(m, dict) or not m.get("output"):
            out.append(f"[hypr] monitors[{i}]: needs an output")
            continue
        outputs.add(m["output"])
        if "scale" in m and not (isinstance(m["scale"], (int, float)) or m["scale"] == "auto"):
            out.append(f"[hypr] monitors[{i}]: scale is a number or \"auto\"")
    for output, spec in cfg.get("workspaces", {}).items():
        if outputs and output not in outputs:
            out.append(f"[hypr] workspaces: {output!r} is not in monitors")
        try:
            workspace_numbers(spec)
        except ValueError as e:
            out.append(f"[hypr] {e}")
    return out


def apply(profile: dict | None = None, target: Path = DIR, quiet: bool = False) -> int:
    """Write what changed, remove what is no longer asked for; the count of changes.
    Only files carrying MARK are ever removed or replaced."""
    profile = (machine.load() or {}) if profile is None else profile
    if problems(profile):
        return 0
    changes = 0
    for name, text in render(profile).items():
        f = target / f"{name}.lua"
        old = f.read_text() if f.is_file() else None
        if old is not None and MARK not in old:
            continue                                    # written by hand: not ours to touch
        if text is None:
            if old is not None:
                f.unlink()
                changes += 1
                quiet or removed(f"{f} (generated)")
        elif text != old:
            target.mkdir(parents=True, exist_ok=True)
            f.write_text(text)
            changes += 1
            quiet or added(f"{f} (generated)")
    return changes


def wanted() -> bool:
    """Only for a machine with the hypr component on."""
    return "hypr" in components.selected()
