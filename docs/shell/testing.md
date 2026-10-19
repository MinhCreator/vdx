# Shell testing and release checks

What can be checked, how, and what stays manual. Commit rules ("Before a
commit", "Before a push"): [repo/commits.md](../repo/commits.md) — not repeated here.

## Automated (verified 2026-10-19, all green on `d855ef6`)

| Command | Covers |
|---|---|
| `./install.py check` | all groups below |
| `./install.py check syntax` | py compile, json/jsonc, toml, xml, `bash -n`, `zsh -n`, `luac -p`, qmllint **syntax only** (`/usr/lib/qt6/bin/qmllint`) |
| `./install.py check shell` | icons and their solid / rounded twins, module ids registered in `ModuleFaces` and `components.toml`, the settings search index current |
| `./install.py check tests` | `tests/` (unittest): installer, `files.py`, `display.py`, `backup.py`, shell gating, portal config, settings migrate / export-import / search index |
| `./install.py check hypr` | `Hyprland --verify-config` with and without `machine/` |
| `./install.py check components` | the catalog against the repo and pacman |
| `ruff check` | Python lint (`ruff.toml`) |
| `git ls-files '*.sh' \| grep -v ^packages/nvim \| xargs shellcheck -S warning` | shell scripts |
| `tests/fresh-machine.sh [defaults \| component…]` | clean Arch in podman: setup, doctor, verify, second setup, uninstall (slow; not run in the 2026-10-19 pass) |

No QML behaviour tests exist. Logic that can live in a backend script (or a
pure JS file) SHOULD go there so a `tests/test_*.py` can cover it.

## Shell runtime checks (manual)

- Log: `qs log -c shell | grep -E 'ERROR|WARN'` — empty after the change.
- Restart (new files, IPC changes): see `shell/CLAUDE.md` › Work.
- Open a surface: `qs -c shell ipc call <target> toggle`.
- Screenshot: `grim -g "X,Y WxH" out.png`.
- Notifications: `notify-send -a Test "title" "body"`; mako state `makoctl list -j`, `makoctl history -j`, `makoctl mode`.
- Audio: `pactl list sources`, `pactl -f json list sinks`.
- Wallpaper: `awww query`; cache `~/.cache/awww/<version>/`.
- Settings state: stop the shell before editing `modules.json` by hand (it is written on exit).

## Regression scenarios by area

Each phase lists the ones it touches; these are the shared base.

| Area | Scenarios |
|---|---|
| Bar styles | Solid and Island; one and two monitors; child bars; open each touched popup; hub from the clock |
| Appearance | sharp / round corners; outlined / material controls; accent off / on; one non-gruvbox theme |
| Settings | value persists across a shell restart; applies without restart; reopen the page; default when the key is absent |
| Optional parts | the feature's component off (`./install.py components remove <c>`, `link`): no QML errors, module "not installed" |
| Missing hardware / service | binary absent, service stopped, no device: the UI shows a state, the log stays clean |
| Lock | lock, wrong password, right password, every monitor, after a theme switch |
| UI states | default, hover, focus (keyboard), active / selected, disabled, loading, error, empty, unavailable — each that applies to the touched control or view |
| Settings lifecycle | reset to default; migration from an old state file (copy of `by-shell/<id>/`); two settings that affect one feature changed in both orders |

## Known limits

- The agent cannot see the screen unless it takes a screenshot; visual checks
  are the owner's unless asked (token cost).
- Overlays that grab the keyboard are not tested while the owner types.
- `sudo` steps (`system install`) are run by the owner.
