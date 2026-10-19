# 09 — Music: optional Yandex Music, generic player module, Yandex Music app

Spec: §10. Shell paths are under `packages/quickshell/shell/`. Three parts,
in order A → B → C. The submodule `packages/scripts/yandex-music` is changed
in its own repository only (CLAUDE.md).

## Read first (all)

`components.toml` (`mpd`, `yandex-music`, `radio`), `modules/music/*`,
`modules/mpd/MpdService.qml`, `modules/radio/*`, `scripts/music.sh`,
`scripts/yandex_likes.py`, `bar/island/IslandService.qml` (media),
`bar/island/IslandMedia.qml`, `modules/audio/AudioPause.qml`,
`packages/mpd/{mpd.conf,dirs.conf,package.toml}`, `installer/shell.py`,
`tests/test_shell.py`, `CONVENTIONS.md` › Components, `shell/README.md` › Requirements.

## Findings so far

- Already optional: component `yandex-music` (default off, requires `mpd`,
  submodule, `links` scripts/yandex-music + zsh function, module `music`, secret).
- Coupling: `IslandService` and `AudioPause` import `MusicService`/`MpdService`
  unconditionally; island media prefers MPD then MPRIS; `scripts/yandex_likes.py`
  ships with quickshell; `mpd.conf` music dir `~/Music/yandex` (a submodule constraint).

---

## Part A — Yandex Music fully optional

Status: Not started · Category: A/B · Depends on: nothing · Gate: none for
fixes; owner approval for moving files between components.

- Audit: with `yandex-music` (and `mpd`) off, does `qs` log errors (services
  probing `mpc`, `yandex-music-cli`)? Install, update, `doctor`, uninstall with it off/on.
- Fix: services idle when their component is off (read `components.json`
  through the existing gating), island media falls back to MPRIS only; move
  `yandex_likes.py` under the `yandex-music` component's `links` if the link model allows (it lives in the quickshell tree — check `links` longest-match ownership).
- Test: `tests/test_shell.py` / `test_components.py` for the ownership;
  `tests/fresh-machine.sh quickshell` (no yandex) — slow, owner agrees first.

Acceptance: fresh machine without the component — setup, doctor, shell start
with a clean log; island media works with an MPRIS player; adding the component later works.

## Part B — Provider-independent player module

Status: Not started · Category: B/C · Depends on: A · Gate: naming + UX + data model approved.

- Rename: the current `music` module → a Yandex-specific id (e.g. `yandex`),
  via `BarLayout.renamed` (layouts keep their place), `components.toml`,
  `ModuleFaces`, `ModuleSettings` keys migration.
- New `player` (or `music`) module on `Quickshell.Services.Mpris`: title,
  artist, art, state, play/pause, next/prev, extra actions the player exposes
  (shuffle, loop, seek, raise); multiple players (choice / most recent active);
  no player; metadata missing; player vanishes mid-play.
- One media model: island media and the new module read one service (no
  second engine); MPD (radio, Yandex via mpd-mpris?) appears as an MPRIS player
  or through an adapter — decide in the proposal.
- Reuse the current Music popup's visual patterns (cover, track rows, controls) for the generic module; keep provider logic out of it.
- References (record): MPRIS D-Bus spec (specifications.freedesktop.org/mpris-spec),
  Quickshell Mpris docs, GNOME / KDE media controls.

Acceptance: Spotify/Firefox/mpv each controllable; two players switch; none → empty state; island shows the same data.

## Part C — Yandex Music application

Status: Not started · Category: C · Depends on: B · Gate: architecture, UX,
features, dependencies, settings approved; decision record.

- Audit the submodule (`yandex-music-cli`, `manager.py`), `yandex_likes.py`,
  token handling (`private/`, secrets), what works today (likes queue, sync, likes toggle).
- Feature table: implemented / missing / duplicated with Part B / app vs module.
- Integration: the unofficial `yandex-music` Python library (MarshalX) — no
  official public API is known; record its status, licence, maintenance and
  ToS risk at research time; nothing assumed. Playback stays in MPD unless the proposal argues otherwise.
- UX: library, search, playlists, queue, likes, now playing — screens and states, within what the library supports.
- Settings and journeys; app registry entry (`apps/apps.json`), its own window.

Acceptance: defined by the approved proposal.

---

## Validation

`./install.py check` (components, tests, shell); `qs log -c shell`;
`playerctl -l` (if installed) or `busctl --user list | grep mpris`;
`./install.py components remove yandex-music && ./install.py link`, then add back.

## Regressions

Radio module (shares MPD); `AudioPause` (pause on other sound); island media
view, hub player, equalizer; `music` zsh function; mpd drop-in (`bc66b6c`).

## Agents

None by default; C's implementation may be split if the owner asks.

## Forbidden

Editing the submodule here; a second audio engine; storing tokens in the repo.

## Report

Per part, README formats.
