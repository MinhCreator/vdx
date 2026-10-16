"""dotfiles installer — secrets, shell plugins, submodules and the full setup of a fresh machine."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys

from . import components
from .deps import cmd_deps
from .links import cmd_link, cmd_verify
from .paths import HOME, ROOT, SEED, TGT
from .preflight import preflight
from .system import cmd_system_install
from .ui import added, confirm, heading, note, ok, short

OMZ = HOME / ".local" / "share" / "oh-my-zsh"       # matches $ZSH in .zshrc
OMZ_INSTALL = "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
# repos cloned once when missing: (target, url)
CLONES = [
    (OMZ / "custom" / "plugins" / "zsh-autosuggestions", "https://github.com/zsh-users/zsh-autosuggestions"),
    (OMZ / "custom" / "plugins" / "zsh-syntax-highlighting", "https://github.com/zsh-users/zsh-syntax-highlighting"),
    (TGT / "tmux" / "plugins" / "tpm", "https://github.com/tmux-plugins/tpm"),
]


def cmd_bootstrap(args) -> int:
    heading("Seeding secrets")
    jobs = [
        (SEED / "env.example", TGT / "secrets" / "env", 0o600, "secrets env"),
    ]
    for src, tgt, mode, label in jobs:
        if not src.is_file():
            continue
        if tgt.exists() and not getattr(args, "force", False):
            note(f"{label}: {short(tgt)} exists, kept")
            continue
        tgt.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, tgt)
        os.chmod(tgt, mode)
        added(f"{label} -> {short(tgt)}")
    return 0


def cmd_secrets(args) -> int:
    """Secret files from the private repo (private/, see private/secrets.py)."""
    script = ROOT / "private" / "secrets.py"
    heading("Secrets (private/)")
    if not script.is_file():
        note("private/ is not cloned: git clone git@github.com:diominvd/secrets.git private")
        return 0
    action = getattr(args, "s_action", "status")
    sys.stdout.flush()
    subprocess.run([sys.executable, "-I", str(script), action], check=True)
    return 0


def shell_extras(args=None) -> int:
    heading("Shell plugins")
    if not OMZ.is_dir():
        added("oh-my-zsh")
        script = subprocess.run(["curl", "-fsSL", OMZ_INSTALL], capture_output=True, text=True, check=True).stdout
        subprocess.run(["sh", "-c", script, "", "--unattended", "--keep-zshrc"],
                       env={**os.environ, "ZSH": str(OMZ), "RUNZSH": "no", "CHSH": "no"}, check=True)
    for target, url in CLONES:
        if not target.is_dir():
            added(short(target))
            subprocess.run(["git", "clone", "--depth", "1", "-q", url, str(target)], check=True)
    ok("oh-my-zsh, zsh plugins and TPM in place")
    return 0


def submodules(args=None) -> int:
    """Only the selected components' submodules (someone else's VPN is not cloned)."""
    heading("Submodules")
    cat = components.load()
    paths = components.unique(components.selected(cat=cat), cat, "submodules")
    if not paths:
        ok("no submodules selected")
        return 0
    subprocess.run(["git", "-C", str(ROOT), "submodule", "update", "--init", "--recursive", "--", *paths], check=True)
    ok(f"{len(paths)} submodule(s) up to date")
    return 0


def cmd_setup(args) -> int:
    """Fresh machine, idempotent: every step skips what is already in place."""
    heading("Setup: packages, submodules, links, secrets, shell plugins, system files")
    if not preflight():
        return 1
    if not confirm("Run the full setup (asks for sudo for packages and /etc)?", args):
        return 1
    args.yes = True
    args.s_action = "restore"
    for step in (cmd_deps, submodules, cmd_link, cmd_bootstrap, cmd_secrets, shell_extras, cmd_system_install):
        step(args)
    return cmd_verify(args)
