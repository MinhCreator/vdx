# Shell testing and release checks

What can be checked, how, and what stays manual. Commit rules ("Before a
commit", "Before a push"): [repo/commits.md](../repo/commits.md) — not repeated here.

## Automated

| Command | Covers |
|---|---|
| `./install.py check` | all groups below |
| `./install.py check syntax` | py compile, json/jsonc, toml, xml, `bash -n`, `zsh -n`, `luac -p`, qmllint **syntax only** (`/usr/lib/qt6/bin/qmllint`) |
| `./install.py check shell` | icons and their solid / rounded twins, module ids registered in `ModuleFaces` and `components.toml`, the settings search index current |
| `./install.py check tests` | `tests/` (unittest): installer and doctor, `files.py`, `display.py`, `backup.py`, shell gating, portal config, settings migrate / export-import / search index, `supervise.sh` (a kill, a config error, a crash loop, its toasts dismissed) |
| `./install.py check hypr` | `Hyprland --verify-config` with and without `machine/` |
| `./install.py check components` | the catalog against the repo and pacman |
| `ruff check` | Python lint (`ruff.toml`) |
| `python tests/check_shell_ui.py` | offscreen QML behaviour: shared controls, keyboard, disabled/busy states, inline selects, grouping, layout copies and backend reply parsing |
| `git ls-files '*.sh' \| grep -v ^packages/nvim \| xargs shellcheck -S warning` | shell scripts |
| `tests/fresh-machine.sh [defaults \| component…]` | clean Arch in podman: setup, doctor, verify, second setup, uninstall (slow) |

The QML harness uses an isolated, memory-only settings store and substitutes
Quickshell's clipping rectangle. It does not verify GPU rendering, compositor
focus, hardware, or real system actions. It runs separately from unittest.
Logic that can live in a backend script or a pure JS file SHOULD go there so
it can be tested independently.

## Shell runtime checks (manual)

- Log: `qs log -c shell | grep -E 'ERROR|WARN'` — empty after the change.
- Restart (new files, IPC changes): see `packages/quickshell/shell/CLAUDE.md` › Work. From a terminal
  opened before Hyprland restarted, `HYPRLAND_INSTANCE_SIGNATURE` is stale: a shell
  started from it has no Hyprland (start it through `hyprctl -i <instance> eval …`,
  the instance from `hyprctl instances -j`).
- Open a surface: `qs -c shell ipc call <target> toggle`.
- Screenshot: `grim -g "X,Y WxH" out.png`.
- Notifications: `notify-send -a Test "title" "body"`; mako state `makoctl list -j`, `makoctl history -j`, `makoctl mode`.
- Audio: `pactl list sources`, `pactl -f json list sinks`.
- Wallpaper: `awww query`; cache `~/.cache/awww/<version>/`.
- Settings state: stop the shell before editing `modules.json` by hand (it is written on exit).

## Regression scenarios by area

Each area lists the scenarios it touches; these are the shared base.

| Area | Scenarios |
|---|---|
| Bar styles | Solid and Island; one and two monitors; child bars; open each touched popup; hub from the clock |
| Appearance | sharp / round corners; outlined / material controls; accent off / on; one non-gruvbox theme |
| Settings | value persists across a shell restart; applies without restart; reopen the page; default when the key is absent |
| Optional parts | the feature's component off (`./install.py components remove <c>`, `link`): no QML errors, module "not installed" |
| Missing hardware / service | binary absent, service stopped, no device: the UI shows a state, the log stays clean |
| Files: USB | plug a stick: a USB row appears (unmounted: size shown, power button); its button mounts it (eject then); the eject button unmounts; unplug: the row goes. Only a real stick tests this |
| Lock | lock, wrong password, right password, every monitor, after a theme switch |
| UI states | default, hover, focus (keyboard), active / selected, disabled, loading, error, empty, unavailable — each that applies to the touched control or view |
| Settings lifecycle | reset to default; migration from an old state file (copy of `by-shell/<id>/`); two settings that affect one feature changed in both orders |

## Known limits

### Audit checkpoint (2026-10-29)

The first refactoring pass covers shared reply parsing, select activation and
pending states, launcher search/navigation, and Files selection/picker rules.
The offscreen harness runs again after removing references to the retired
custom colour field and updating its isolated settings/layout hosts.

Validation: 219 Python tests and 44 QML test cases pass; shell, syntax,
components, Hyprland and Python lint checks pass. Shell Manager Bar and
Appearance were visually inspected at the existing window size. Navigation
to Themes, Fonts, Cursor, Files settings, Network, Sound, Notifications, Hub,
Live and About produced no new QML errors. This is a page-loading check,
not a test of every action on those pages.

Still required for a full audit: per-function review of the remaining apps
and services; capture/lock/portal lifecycles; real device and multiple-monitor
scenarios; rendering in both styles and themes; performance measurement and
decomposition of the largest services (especially FilesService). Passing the
baseline checks does not establish coverage of these scenarios.

- The agent cannot see the screen unless it takes a screenshot; visual checks
  are the owner's unless asked (token cost).
- Overlays that grab the keyboard are not tested while the owner types.
- `sudo` steps (`system install`) are run by the owner.
