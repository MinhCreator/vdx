# Shell roadmap

What is open, in what order. How to run a task: [tasks/README.md](tasks/README.md).
Done work is described in the topic files ([README.md](README.md)); its plans
are in git history.

Updated: 2026-10-20.

## Done

Repository audit; notifications (reappear, click, lifecycle, toast duration,
capture toggles); file picker refresh; one microphone entry per port;
wallpaper after Display changes and at login; Bluetooth "Rescan"; product-wide
UX audit and its fixes (default bar and overflow, supervisor and relock,
idle polling, missing hardware, optional apps, first run, contrast and text
size, monitors and wallpapers, lock marker); Settings redesign (decision 0002:
pages by area, schema version and migrations, resets, export / import, search);
UI rules in `shell/design.md`; Capture freezes first, its choices a toolbar on the overlay (decision 0005).

## Open tasks

Cat: A local fix · B medium · C redesign / new app. Gate: what the owner
approves before code.

| Task | Cat | Depends on | Gate | Status |
|---|---|---|---|---|
| [06](tasks/06_LOCKSCREEN_CUSTOMIZATION.md) Lock screen customisation | B/C | — | proposal | Not started |
| [07](tasks/07_FILE_MANAGER_IMPROVEMENTS.md) Files: A storage home · B custom sidebar · C fewer frames | A/B | A before B | proposal / prototype | Implemented (A, B, C); sidebar sections and USB section added; owner's look pending |
| [08](tasks/08_BAR_ISLAND_AND_NOTCH_MODE.md) A Launcher + Keybinds in the island · B notch bar style | B / C | A before B | concept; B research + decision | A implemented (clicks not run here); B not started |
| [09](tasks/09_MUSIC_SUBSYSTEM.md) A Yandex Music optional · B generic player · C Yandex Music app · D Music app | A–D | A → B → C → D | per part | A and B implemented (fresh-machine test skipped by owner); C superseded by D; D implemented, the owner's look approval open ([decision 0006](decisions/0006-music-app.md), proposed) |
| [12](tasks/12_KEYBOARD_ACCESS.md) Keyboard and assistive access | B/C | — | prototype popup | Not started |
| [10](tasks/10_TORRENT_CLIENT.md) Torrent client | C | 07-A optional | design + engine decision | Not started |
| [13](tasks/13_FINAL_INTEGRATION_AND_REVIEW.md) Integration, regressions, docs | B | each milestone | — | Not started |
| Plugins / user drop-in modules (audit U-16) | C | 13 | decision record | Deferred |
| Lazy loading of windows (memory ~78 MB in windows) | B | — | — | Deferred (owner: no deep optimisation) |

Order: 06 → 07 → 08-A → 09-A/B → 12, then 08-B, 09-C, 10. 13 after each
group. 08-A and 09-A both edit `bar/island/IslandService.qml`: one at a time.
Each plan lists "Files edited"; check it before running two at once.

## Owner checks left

Done in code, not yet seen by the owner:

- Notifications: lifecycle and toast duration on screen; Island style has no
  default click action (limit of mako).
- File picker: the `Choose…` button.
- Microphones: switching to a headset live.
- Wallpaper: a Display scale / position change; a re-login; a plugged monitor;
  Hyprland's background colour at login.
- Lock: stale-marker fix — lock, kill the shell, unlock (steps 3–5).
- A second monitor (bars, wallpapers); `tests/fresh-machine.sh defaults` (~840 MB, needs a yes).
- Files: "This computer" look; the sidebar drag (within PLACES / PINNED), pin, hide and Restore defaults (Settings › SIDEBAR); the USB section with a real stick (plugged, mounted, unmounted by its button, unplugged); the frames removal (screenshot).
- Island: the Launcher and Keys chips by a real click; Escape back to the hub; the outside click; the Solid style unchanged.
- Capture ([decision 0005](decisions/0005-capture-freeze-first.md)): a recording from the toolbar, the Delay countdown, the keys (R W S, Tab, C), a second monitor, the strip style.
- Player: Spotify and a browser (MPRIS); the module's placement in the Folder or the bar (new modules start there); the Yandex module under its new id `yandex` (IPC `yandex`).

## Open questions

| ID | Question | Recommendation | Task |
|---|---|---|---|
| D-06 | Agents: the spec wants Haiku implementers and an Opus reviewer | no agents unless asked per task | all |
| D-10 | Names: module `music` (Yandex) and the generic player | `yandex` + `player` | 09-B |
| D-12 | Torrent engine | after 10's research | 10 |
| D-13 | Notch: a third bar style or an Island variant | after 08-B's research | 08-B |
