"""dotfiles installer — the steps of `setup`, each one: what it would change, then doing it.

A step's `pending(ctx)` only looks (it is the dry run and the plan screen);
`run(ctx)` changes the machine and is called only when something is pending.
Every step is idempotent: run again, it finds nothing to do. `by hand` lines
are things the installer never does itself (a group, a boot setting).
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path

from . import components, detect, machine
from .links import cmd_link
from .model import build_entries, is_same, missing_packages, stale_links, system_state
from .paths import HOME, ROOT, SEED, TGT
from .system import cmd_system
from .ui import added, note, ok, short, warn

OMZ = HOME / ".local" / "share" / "oh-my-zsh"       # matches $ZSH in .zshrc
PLUGINS = OMZ / "custom" / "plugins"
# repos cloned once when missing: component, target, url (git clone, never curl | sh)
CLONES = [
    ("zsh", OMZ, "https://github.com/ohmyzsh/ohmyzsh"),
    ("zsh", PLUGINS / "zsh-autosuggestions", "https://github.com/zsh-users/zsh-autosuggestions"),
    ("zsh", PLUGINS / "zsh-syntax-highlighting", "https://github.com/zsh-users/zsh-syntax-highlighting"),
    ("tmux", TGT / "tmux" / "plugins" / "tpm", "https://github.com/tmux-plugins/tpm"),
]
PRIVATE = ROOT / "private"
PRIVATE_REPO = "diominvd/secrets"
USER_UNITS = TGT / "systemd" / "user"
# units that fight one of ours when both run: ours -> theirs
CONFLICTS = {
    "tlp.service": ["power-profiles-daemon.service", "tuned.service"],
    "NetworkManager.service": ["systemd-networkd.service", "connman.service"],
    "mihomo.service": ["systemd-resolved.service"],          # both want port 53
}


@dataclass
class Ctx:
    """What every step reads: the selection, the catalog, the profile."""
    args: object
    cat: dict
    on: set[str]
    profile: dict = field(default_factory=dict)

    def has(self, name: str) -> bool:
        return name in self.on

    def each(self, key: str) -> list[str]:
        return components.unique(self.on, self.cat, key)


def noconfirm(ctx: Ctx) -> list[str]:
    """--noconfirm for pacman, yay and makepkg when setup was asked for it."""
    return ["--noconfirm"] if getattr(ctx.args, "noconfirm", False) else []


def systemd_running(user: bool = False) -> bool:
    """False in a container or a chroot: units can't be enabled there."""
    if not Path("/run/systemd/system").is_dir():
        return False
    return not user or subprocess.run(["systemctl", "--user", "is-system-running"], capture_output=True).returncode in (0, 1)


def quiet(cmd: list[str]) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, capture_output=True, text=True)


# --------------------------------------------------------------------------- steps

class Step:
    name = ""
    title = ""

    def pending(self, ctx: Ctx) -> list[str]:
        return []

    def by_hand(self, ctx: Ctx) -> list[str]:
        return []

    def run(self, ctx: Ctx) -> None:
        pass


class Packages(Step):
    name, title = "packages", "Packages (pacman)"

    def pending(self, ctx):
        repo, _ = missing_packages()
        return [f"install {' '.join(repo)}"] if repo else []

    def run(self, ctx):
        repo, _ = missing_packages()
        subprocess.run(["sudo", "pacman", "-S", "--needed", *noconfirm(ctx), *repo], check=True)


def aur_helper() -> str | None:
    return shutil.which("paru") or shutil.which("yay")


class AurHelper(Step):
    name, title = "aur-helper", "AUR helper"

    def pending(self, ctx):
        _, aur = missing_packages()
        return ["build yay-bin from the AUR (makepkg)"] if aur and not aur_helper() else []

    def run(self, ctx):
        with tempfile.TemporaryDirectory() as tmp:
            subprocess.run(["git", "clone", "--depth", "1", "-q", "https://aur.archlinux.org/yay-bin.git", tmp + "/yay-bin"],
                           check=True)
            subprocess.run(["makepkg", "-si", "--needed", *noconfirm(ctx)], cwd=tmp + "/yay-bin", check=True)


class Aur(Step):
    name, title = "aur", "Packages (AUR)"

    def pending(self, ctx):
        _, aur = missing_packages()
        return [f"install {' '.join(aur)}"] if aur else []

    def run(self, ctx):
        _, aur = missing_packages()
        helper = aur_helper()
        if not helper:
            raise RuntimeError("no AUR helper: the aur-helper step did not finish")
        subprocess.run([helper, "-S", "--needed", *noconfirm(ctx), *aur], check=True)


def uninitialised_submodules(paths: list[str]) -> list[str]:
    if not paths:
        return []
    r = quiet(["git", "-C", str(ROOT), "submodule", "status", "--", *paths])
    return [line.split()[1] for line in r.stdout.splitlines() if line.startswith("-")]


class Submodules(Step):
    name, title = "submodules", "Submodules"

    def pending(self, ctx):
        return [f"clone {p}" for p in uninitialised_submodules(ctx.each("submodules"))]

    def run(self, ctx):
        paths = ctx.each("submodules")
        subprocess.run(["git", "-C", str(ROOT), "submodule", "update", "--init", "--recursive", "--", *paths], check=True)


class Links(Step):
    name, title = "links", "Links"

    def pending(self, ctx):
        entries = build_entries()
        new = sum(1 for src, tgt, _ in entries if not is_same(tgt, src))
        stale = len(stale_links(entries))
        return ([f"link {new} file(s)"] if new else []) + ([f"remove {stale} stale link(s)"] if stale else [])

    def run(self, ctx):
        cmd_link(ctx.args)


class SecretsTemplate(Step):
    name, title = "secrets-template", "Secrets template"

    def pending(self, ctx):
        tgt = TGT / "secrets" / "env"
        return [f"seed {short(tgt)} from templates/secrets/env.example"] if not tgt.exists() else []

    def run(self, ctx):
        tgt = TGT / "secrets" / "env"
        tgt.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(SEED / "env.example", tgt)
        os.chmod(tgt, 0o600)
        added(short(tgt))


def clone_private_with() -> str:
    """How private/ can be cloned here: ssh, gh, or "" (neither works)."""
    env = {**os.environ, "GIT_SSH_COMMAND": "ssh -o BatchMode=yes -o ConnectTimeout=5"}
    if subprocess.run(["git", "ls-remote", f"git@github.com:{PRIVATE_REPO}.git"], capture_output=True, env=env).returncode == 0:
        return "ssh"
    if shutil.which("gh") and quiet(["gh", "auth", "status"]).returncode == 0:
        return "gh"
    return ""


def missing_secrets() -> list[str]:
    manifest = PRIVATE / "manifest.json"
    if not manifest.is_file():
        return []
    try:
        return [t for t in json.loads(manifest.read_text()).values() if not Path(os.path.expanduser(t)).exists()]
    except (ValueError, AttributeError):
        return []


class Private(Step):
    """The owner's secrets: cloned once, restored only where a file is missing
    (a restore overwrites, and a local edit not yet collected would be lost)."""
    name, title = "private", "Secrets (private/)"

    def pending(self, ctx):
        if not ctx.has("private"):
            return []
        if not PRIVATE.is_dir():
            return [f"clone {PRIVATE_REPO} into private/"]
        missing = missing_secrets()
        return [f"restore {len(missing)} missing secret file(s)"] if missing else []

    def by_hand(self, ctx):
        if ctx.has("private") and not PRIVATE.is_dir() and not clone_private_with():
            return ["private/: no SSH key for GitHub and gh is not signed in — `gh auth login`, then setup again"]
        return []

    def run(self, ctx):
        if not PRIVATE.is_dir():
            how = clone_private_with()
            if how == "ssh":
                subprocess.run(["git", "clone", "-q", f"git@github.com:{PRIVATE_REPO}.git", str(PRIVATE)], check=True)
            elif how == "gh":
                subprocess.run(["gh", "repo", "clone", PRIVATE_REPO, str(PRIVATE), "--", "-q"], check=True)
            else:
                warn("private/ not cloned (see the by-hand list)")
                return
        if missing_secrets():
            sys.stdout.flush()
            subprocess.run([sys.executable, "-I", str(PRIVATE / "secrets.py"), "restore"], check=True)


class ShellPlugins(Step):
    name, title = "shell-plugins", "Oh My Zsh, zsh plugins, TPM"

    def todo(self, ctx):
        return [(t, url) for comp, t, url in CLONES if ctx.has(comp) and not t.is_dir()]

    def pending(self, ctx):
        return [f"clone {short(t)}" for t, _ in self.todo(ctx)]

    def run(self, ctx):
        for target, url in self.todo(ctx):
            subprocess.run(["git", "clone", "--depth", "1", "-q", url, str(target)], check=True)
            added(short(target))


class System(Step):
    name, title = "system", "Files in /etc"

    def pending(self, ctx):
        return [f"copy {dst} ({s})" for _, dst, s in system_state() if s in ("differs", "missing")]

    def run(self, ctx):
        ctx.args.s_action = "install"
        cmd_system(ctx.args)


class UserUnits(Step):
    name, title = "user-units", "User units"

    def todo(self, ctx):
        out = []
        for p in ctx.each("user_units"):
            src, dst = ROOT / p, USER_UNITS / Path(p).name
            if src.is_file() and (not dst.is_file() or dst.read_bytes() != src.read_bytes()):
                out.append((src, dst))
        return out

    def pending(self, ctx):
        return [f"copy {short(dst)}" for _, dst in self.todo(ctx)]

    def run(self, ctx):
        for src, dst in self.todo(ctx):
            dst.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dst)
            added(short(dst))
        subprocess.run(["systemctl", "--user", "daemon-reload"], check=False)


def enabled(unit: str, user: bool = False) -> str:
    """systemctl is-enabled: enabled, disabled, static, masked, not-found, ..."""
    r = quiet(["systemctl", *(["--user"] if user else []), "is-enabled", unit])
    return (r.stdout.strip() or "not-found").splitlines()[0]


def active(unit: str, user: bool = False) -> bool:
    return quiet(["systemctl", *(["--user"] if user else []), "is-active", unit]).stdout.strip() == "active"


def failed(unit: str, user: bool = False) -> bool:
    return quiet(["systemctl", *(["--user"] if user else []), "is-failed", unit]).stdout.strip() == "failed"


class Services(Step):
    name, title = "services", "Services"

    def todo(self, ctx):
        on, user_on = systemd_running(), systemd_running(user=True)
        system = [u for u in ctx.each("services") if on and enabled(u) not in ("enabled", "static", "not-found")]
        user = [u for u in ctx.each("user_services") if user_on and enabled(u, True) not in ("enabled", "static", "not-found")]
        masks = [u for u in ctx.each("masks") if on and enabled(u) != "masked"]
        return system, user, masks

    def pending(self, ctx):
        system, user, masks = self.todo(ctx)
        return ([f"enable {u}" for u in system] + [f"enable {u} (--user)" for u in user]
                + [f"mask {u}" for u in masks])

    def by_hand(self, ctx):
        if not systemd_running():
            units = ctx.each("services") + ctx.each("user_services") + ctx.each("masks")
            return [f"systemd is not running here (a container, a chroot): enable after boot — {' '.join(units)}"] if units else []
        out = []
        for ours, theirs in CONFLICTS.items():
            if ours in ctx.each("services") + ctx.each("user_services"):
                out += [f"{t} is running and fights {ours}: sudo systemctl disable --now {t}" for t in theirs if active(t)]
        missing = [u for u in ctx.each("services") if enabled(u) == "not-found"]
        missing += [u for u in ctx.each("user_services") if enabled(u, True) == "not-found"]
        out += [f"{u}: no such unit yet — setup again after its package is installed" for u in missing]
        return out

    def run(self, ctx):
        system, user, masks = self.todo(ctx)
        if system:
            subprocess.run(["sudo", "systemctl", "enable", "--now", *system], check=True)
        if masks:
            subprocess.run(["sudo", "systemctl", "mask", *masks], check=True)
        if user:
            subprocess.run(["systemctl", "--user", "enable", "--now", *user], check=True)


class LoginShell(Step):
    name, title = "login-shell", "Login shell"

    def pending(self, ctx):
        zsh = shutil.which("zsh")
        if not ctx.has("zsh") or not zsh:
            return []
        current = detect.environment()["shell"]
        return [f"chsh -s {zsh} (now {current})"] if Path(current).name != "zsh" else []

    def run(self, ctx):
        # through sudo like every system step: chsh itself asks for the password through PAM
        subprocess.run(["sudo", "chsh", "-s", shutil.which("zsh"), os.environ.get("USER") or detect.environment()["user"]],
                       check=True)


class Groups(Step):
    """Group membership is a privilege: never changed here, only named."""
    name, title = "groups", "Groups"

    def by_hand(self, ctx):
        groups = detect.environment()["groups"]
        if ctx.has("quickshell") and "wheel" not in groups:
            return ["not in wheel: the shell's root actions and battery limits need it — "
                    f"sudo usermod -aG wheel {os.environ.get('USER', '$USER')}, then log in again"]
        return []


class Neovim(Step):
    name, title = "nvim-plugins", "Neovim plugins"

    def pending(self, ctx):
        lazy = HOME / ".local" / "share" / "nvim" / "lazy" / "lazy.nvim"
        return ["install the locked plugins (Lazy! restore)"] if ctx.has("nvim") and shutil.which("nvim") and not lazy.is_dir() else []

    def run(self, ctx):
        subprocess.run(["nvim", "--headless", "+Lazy! restore", "+qa"], check=False)


class Hints(Step):
    name, title = "hints", "Manual steps of the components"

    def by_hand(self, ctx):
        return [f"{n}: {line}" if i == 0 else f"  {line}"
                for n in ctx.cat if ctx.has(n) and ctx.cat[n].get("hint")
                for i, line in enumerate(ctx.cat[n]["hint"].splitlines())]


STEPS: list[Step] = [Packages(), AurHelper(), Aur(), Submodules(), Links(), SecretsTemplate(), Private(),
                     ShellPlugins(), System(), UserUnits(), Services(), LoginShell(), Groups(), Neovim(), Hints()]


def context(args) -> Ctx:
    cat = components.load()
    profile = machine.load() or {}
    return Ctx(args=args, cat=cat, on=components.selected(profile, cat), profile=profile)


def plan(ctx: Ctx, steps: list[Step] | None = None) -> list[tuple[Step, list[str], list[str]]]:
    """(step, what it would change, what is left by hand) for every step."""
    return [(s, s.pending(ctx), s.by_hand(ctx)) for s in (STEPS if steps is None else steps)]


def show_plan(rows) -> None:
    for step, todo, manual in rows:
        if not todo and not manual:
            ok(f"{step.title}: nothing to do")
            continue
        (warn if todo else note)(f"{step.title}")
        for line in todo:
            print(f"      {line}")
        for line in manual:
            print(f"      by hand: {line}")
