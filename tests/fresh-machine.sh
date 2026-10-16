#!/usr/bin/env bash
#
# fresh-machine.sh — the installer on a clean Arch, in a podman container.
#
#   tests/fresh-machine.sh [component ...]     default: a small terminal set + vpn
#
# Clones the committed repo as a new user would, picks the components, runs
# setup unattended, then checks what a user would: doctor, verify, a second
# setup with nothing to do, uninstall. No systemd and no display in a
# container: services are listed by hand, Hyprland isn't started.
# KEEP=1 leaves the container for a look (podman exec -it -u tester dotfiles-fresh bash).

set -euo pipefail

NAME=dotfiles-fresh
ROOT=$(cd "$(dirname "$0")/.." && pwd)
PICK=("${@:-zsh kitty tmux btop fastfetch gh scripts vpn}")
PICK=(${PICK[*]})

step() { printf '\n\033[1;36m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
as_root() { podman exec "$NAME" bash -c "$1"; }
as_user() { podman exec -u tester -w /home/tester/.dotfiles "$NAME" bash -lc "$1"; }
fail() { printf '\033[31mFAIL:\033[0m %s\n' "$*"; exit 1; }

podman rm -f "$NAME" >/dev/null 2>&1 || true
[[ ${KEEP:-} ]] || trap 'podman rm -f "$NAME" >/dev/null 2>&1 || true' EXIT

step "a clean Arch"
podman run -d --name "$NAME" -v "$ROOT:/src:ro" docker.io/library/archlinux:latest sleep infinity >/dev/null
as_root "pacman -Syu --noconfirm --needed git python sudo >/dev/null
         useradd -m -G wheel tester
         echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel"

step "clone, as a new user would"
podman exec -u tester "$NAME" bash -c "git config --global --add safe.directory '*' &&
                                       git clone -q /src /home/tester/.dotfiles"

step "machine, components: ${PICK[*]}"
as_user "./install.py machine detect -y >/dev/null && ./install.py components set ${PICK[*]} -y | tail -n +2"

step "setup --dry-run"
as_user "./install.py setup --dry-run"

step "setup"
as_user "./install.py setup -y --noconfirm" || fail "setup"

step "doctor"
as_user "./install.py doctor" || fail "doctor"

step "verify"
as_user "./install.py verify" || fail "verify"

step "setup again: nothing to do"
again=$(as_user "./install.py setup --dry-run | tail -1")
echo "$again"
grep -q "nothing to do" <<<"$again" || fail "a second setup still has work"

step "login shell"
as_user "getent passwd tester | cut -d: -f7" | grep -q zsh || fail "the login shell is not zsh"

step "uninstall"
as_user "./install.py uninstall -y --system >/dev/null && ./install.py verify >/dev/null" && fail "links left after uninstall"
as_user "test -z \"\$(find ~ -lname '*/.dotfiles/*' 2>/dev/null)\"" || fail "a link into the repo survived"

printf '\n\033[32mOK\033[0m fresh machine: %s\n' "${PICK[*]}"
