"""dotfiles installer — `components`: list them, switch them on and off.

A change is saved to .machine.toml and linked at once; packages are only
reported (`./install.py deps` installs them, nothing is ever uninstalled).
"""

from __future__ import annotations

from . import components, detect, machine
from .links import cmd_link
from .model import missing_packages
from .ui import bold, confirm, cyan, dim, err, green, heading, note, warn


def save(names: set[str], cat: dict) -> None:
    profile = machine.load() or {}
    profile.setdefault("version", machine.VERSION)
    profile.setdefault("hardware", detect.hardware())
    profile["components"] = components.record(names, cat)
    machine.save(profile)


def show(cat: dict, on: set[str], profile: dict | None) -> None:
    hw = machine.hardware(profile)
    for group in components.GROUPS[1:]:
        names = [n for n, c in cat.items() if c["group"] == group]
        if not names:
            continue
        print(f"\n  {bold(group)}")
        for n in names:
            c = cat[n]
            tick = green("[x]") if n in on else dim("[ ]")
            why = []
            if group == "hardware":
                why.append("detected" if components.detected(c, hw) else "not detected")
            if n in on and (by := components.required_by(n, on, cat)):
                why.append("required by " + ", ".join(by))
            tail = dim(" · " + " · ".join(why)) if why else ""
            print(f"  {tick} {cyan(f'{n:26s}')} {c['about']}{tail}")


def cmd_components(args) -> int:
    action = getattr(args, "c_action", None) or "list"
    names = list(getattr(args, "names", None) or [])
    cat = components.load()
    profile = machine.load()
    on = components.selected(profile, cat)

    if action == "list":
        heading("Components" + ("" if components.saved(profile) is not None
                                else dim(" (nothing chosen yet: everything detected is on)")))
        show(cat, on, profile)
        return 0

    unknown = [n for n in names if n not in cat]
    if unknown or not names:
        err(f"no such component: {', '.join(unknown)}" if unknown else f"name a component to {action}")
        note(f"have: {', '.join(n for n, c in cat.items() if c['group'] != 'core')}")
        return 2

    if action == "set":
        new = components.closure(set(names), cat)
        heading("Setting the components: " + ", ".join(names))
        for n in [n for n in cat if n in new - on]:
            note(f"+ {n}")
        for n in [n for n in cat if n in on - new]:
            note(f"- {n}")
        if on - new and not confirm("Remove the links of those that go (installed packages stay)?", args):
            return 1
    elif action == "add":
        new = components.closure(on | set(names), cat)
        heading("Adding " + ", ".join(names))
        if new == on:
            note("already on")
            return 0
        for n in [n for n in cat if n in new - on]:
            note(f"+ {n}" + (dim("  (required)") if n not in names else ""))
    else:
        heading("Removing " + ", ".join(names))
        core = [n for n in names if cat[n]["group"] == "core"]
        if core:
            err(f"{', '.join(core)}: always on")
            return 1
        blocked = {n: [b for b in components.required_by(n, on, cat) if b not in names] for n in names}
        blocked = {n: by for n, by in blocked.items() if by}
        if blocked:
            for n, by in blocked.items():
                err(f"{n} is required by {', '.join(by)}: remove them too")
            return 1
        new = components.closure(on - set(names), cat)
        if new == on:
            note("already off")
            return 0
        for n in [n for n in cat if n in on - new]:
            note(f"- {n}")
        if not confirm("Remove their links (installed packages stay)?", args):
            return 1

    save(new, cat)
    code = cmd_link(args)
    repo, aur = missing_packages()
    if repo or aur:
        warn(f"packages to install: {' '.join(repo + aur)} — `./install.py deps`")
    return code
