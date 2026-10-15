# shell

Quickshell config (`qs -c shell`): the bar, the shell's apps and the Shell
Manager. Code rules: [CLAUDE.md](CLAUDE.md).

## Apps

Registry: `apps/apps.json` (the Shell Manager, the system menu,
`scripts/shellapps.py` and the window rules read it).

| App | Key | IPC |
|---|---|---|
| Shell Manager | Super+S | `shell toggle`, `shell open <page>[:<group or app>]` |
| Task manager | Super+D | `taskmanager toggle` |
| Cleaner | Super+X | `cleaner toggle` |
| Capture | Super+Shift+S | `capture open\|stop\|close` |
| System menu | Super+R | `launcher toggle` |
| Overview | — | `overview toggle` |
| Lock screen | Super+Z | `lock lock` |
| Taskbar | — | floating mode only |
| Root prompt | — | polkit agent; asks before every root action |

IPC: `qs -c shell ipc call <target> <function>`. Window mode:
`windowmode set tiling|floating|scrolling`.

## Modules

Bar modules live in `modules/<id>/`; each popup opens with
`qs -c shell ipc call <id> toggle`. Order, zones and visibility: Shell Manager
› Bar. Options: Shell Manager › Modules (an app's module: › Shell apps).

Workspaces, Music, Radio, Clock, Display, Audio, Wi-Fi, Mihomo, Battery,
Language, AI, Shell, Notifications, Capture, Clipboard, System, Task manager,
Cleaner, Windows, Chat, Folder.

## Requirements

| What | Needs |
|---|---|
| Battery limit, power profile | `system/etc/tmpfiles.d/quickshell-power.conf` |
| Headset mic | `system/etc/tmpfiles.d/headset-mic.conf` |
| Root actions without a password for 5 min | `system/etc/polkit-1/rules.d/50-pkexec-keep.rules` |
| Ollama service switch | `system/etc/polkit-1/rules.d/50-ollama.rules` |
| AI limits | Claude Code login (`~/.claude/.credentials.json`) |
| Music likes | Yandex Music token (`~/.config/scripts/yandex-music/token`) |

System files: `./install.py system install`.

## Files you edit

| File | What |
|---|---|
| `modules/brightness/night_light.json` | night light presets and schedule |
| `modules/wifi/dns_providers.json` | DNS providers: `{label, servers}` |
| `~/.config/scripts/radio/stations.json` | radio stations: `"key": {name, url}` |

State: `~/.local/state/quickshell/by-shell/<id>/` (`settings.json`,
`modules.json`, `layout.json`, …) and `~/.local/state/dotfiles/`
(`window-mode`, `windows.json`, `shell-apps.json`).
