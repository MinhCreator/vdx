# 09 — Music: optional Yandex Music, generic player module, Music app

Spec: §10. Shell paths are under `packages/quickshell/shell/`. Four parts,
in order A → B → C → D. The submodule `packages/scripts/yandex-music` is changed
in its own repository only (CLAUDE.md).

## Read first (all)

`components.toml` (`mpd`, `yandex-music`, `radio`), `modules/music/*`,
`modules/mpd/MpdService.qml`, `modules/radio/*`, `scripts/music.sh`,
`scripts/yandex_likes.py`, `bar/island/IslandService.qml` (media),
`bar/island/IslandMedia.qml`, `modules/audio/AudioPause.qml`,
`packages/mpd/{mpd.conf,dirs.conf,package.toml}`, `installer/shell.py`,
`tests/test_shell.py`, `docs/repo/components.md`, `shell/README.md` › Requirements.

## Findings so far

- Already optional: component `yandex-music` (default off, requires `mpd`,
  submodule, `links` scripts/yandex-music + zsh function, module `music`, secret).
- Coupling: `IslandService` and `AudioPause` import `MusicService`/`MpdService`
  unconditionally; island media prefers MPD then MPRIS; `scripts/yandex_likes.py`
  ships with quickshell; `mpd.conf` music dir `~/Music/yandex` (a submodule constraint).

---

## Part A — Yandex Music fully optional

Status: Implemented, partially verified (MPD listener idles with both music
components off; `yandex_likes.py` moved to the component's ownership (now `scripts/yandex.py`); the fresh-machine test skipped by the owner 2026-10-20) · Category: A/B ·
Depends on: nothing · Gate: none for fixes; owner approval for moving files
between components.

- Audit: with `yandex-music` (and `mpd`) off, does `qs` log errors (services
  probing `mpc`, `yandex-music-cli`)? Install, update, `doctor`, uninstall with it off/on.
  Found: `MpdService` started `music.sh --listen` at shell start even with
  `yandex-music` and `radio` off (a poll loop every 2 s, restart every 5 s).
  Fix: `MpdService.needed` = music or radio installed (`BarLayout.installed`);
  the listener starts and stops with it. Island media already falls back to MPRIS
  (`MpdService.stopped`), `AudioPause` reads MPRIS too. Checked live: both off →
  no `music.sh --listen`; back on → it returns. `mpd.service` itself is not
  stopped by this (the component's link/user service is the owner's call).
  Not done: a fresh machine without the component (`fresh-machine.sh quickshell`,
  owner agrees first); the `yandex-music-cli` side with `mpc` missing.
- Fix: services idle when their component is off (read `components.json`
  through the existing gating), island media falls back to MPRIS only; move
  `yandex_likes.py` under the `yandex-music` component's `links` if the link model allows (it lives in the quickshell tree — check `links` longest-match ownership).
- Test: `tests/test_shell.py` / `test_components.py` for the ownership;
  `tests/fresh-machine.sh quickshell` (no yandex) — slow, owner agrees first.

Acceptance: fresh machine without the component — setup, doctor, shell start
with a clean log; island media works with an MPRIS player; adding the component later works.

## Part B — Provider-independent player module

Status: Implemented, partially verified (owner approved 2026-10-20: names `yandex` and `player`, MPRIS plus MPD in one list). Verified live with a test MPRIS player (two players, Next, the popup, the island, the hub chip); mpv has no MPRIS here (`mpv-mpris` not installed), Spotify and Firefox not tried. · Category: B/C · Depends on: A · Gate: naming + UX + data model approved.

Done: the module `music` is `yandex` (folder `modules/yandex/`, `YandexService`, `BarLayout.renamed`, settings `modules.json` version 3); `modules/player/` (`PlayerService`: the MPD source and every MPRIS player, the pick in the popup, else a playing one, MPD first; `Player.qml`, `PlayerPopup.qml` with shuffle, repeat and raise where the player has them); the island's media reads `PlayerService`; the `player` module is in the quickshell component (new modules start in the Folder).

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

Status: Implemented, partially verified · Category: C · Depends on: B · Gate:
[decision 0004](../decisions/0004-yandex-music-app.md) accepted 2026-10-20 (owner, chat); the owner's look
approval and the search / playlist clicks are still open.

- Audit the submodule (`yandex-music-cli`, `manager.py`), `yandex_likes.py`,
  token handling (`private/`, secrets), what works today (likes queue, sync, likes toggle).
- Feature table: implemented / missing / duplicated with Part B / app vs module.
- Integration: the unofficial `yandex-music` Python library (MarshalX) — no
  official public API is known; record its status, licence, maintenance and
  ToS risk at research time; nothing assumed. Playback stays in MPD unless the proposal argues otherwise.
- UX: library, search, playlists, queue, likes, now playing — screens and states, within what the library supports.
- Settings and journeys; app registry entry (`apps/apps.json`), its own window.

Acceptance: defined by the approved proposal.

## Part D — Music app (the Yandex window redesigned)

Status: Implemented, partially verified · Category: C · Depends on: C · Gate:
[decision 0006](../decisions/0006-music-app.md) proposed 2026-10-20 (the owner asked in chat);
the owner's look approval of the window is the gate before more work on it.

Audit of the Yandex window (2026-10-20):
- Look: its own (tabs, "full mode", a bottom box), not the apps' (Files, Shell Manager:
  sidebar pane, a table in a raised box); 640 px wide; the README spoke of an equalizer it never had.
- Scope: MPD only; Spotify, a browser, the radio had no window; "not installed" without Yandex.
- Duplicates: three players (YandexNowPlaying, PlayerPopup, the window's box) each with their own transport.
- Menu: the track menu's hover was `background1` on a `background1` panel (invisible).
- Kept limits (decision 0004): a search or playlist track plays only after the update;
  each window open reads likes, playlists and the likes map from the network.
- `RadioService` asks MPD for stations when first read, installed or not: the window reads it only when installed.

Done: `apps/music/` (MusicWindow, Music, MusicSidebar, MusicNowPlaying, MusicTracks,
MusicPlayerBar, MusicMenu, MusicMenuRow, MusicSettings); `apps/yandex/` removed,
`YandexLibrary` → `modules/yandex/`; `kit/KitSideRow`, `kit/KitSideCaption` (were Files');
apps.json entry `music` (module `player`); IPC `music`; the Player popup's button opens
the window; options moved (`settings_migrate.py` 6, tests).

Open: the owner's look check (prototype = the window); clicks through Likes, Search,
a playlist, Stations and the menus; the Yandex popup onto `PlayerService`; a local
library (needs MPD's music dir decided).

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

## Report — Part C (2026-10-20)

1. Problem: the module plays only the liked tracks; search, playlists and a
   library window were missing. Root cause: none; a new feature (task C).
2. Changes: `scripts/yandex.py` (was `yandex_likes.py`, the git rename) with
   `--likes-list`, `--search`, `--playlists`, `--playlist`; `scripts/music.sh
   --likes-at FILE`; `modules/yandex/YandexService.qml` (`toggleLike(id)`,
   `localIds`, `refreshLikes()`); `apps/yandex/` (YandexWindow, YandexApp,
   YandexLibrary, YandexTrack, YandexTrackList); `apps/apps.json`, `shell.qml`,
   `components.toml` (`yandex.py` owned by `yandex-music`); `tests/test_components.py`;
   the shell README row, `architecture.md`, `roadmap.md`, decision 0004.
3. Why: decision 0004 (playback in MPD; search and playlist tracks play after the update).
4. Validation: `./install.py check` green; 175 unit tests OK; backend commands
   run against the owner's account; the window opens and draws the likes (screenshot);
   shell log clean for yandex after restart.
5. Regressions: the module's popup and bar face read the same `YandexService`
   (its `toggleLike()` without an id still likes the playing track).
6. Open: the owner's look check of the window (design.md, prototype); clicking
   through Search, Playlists and a play from the app; the fresh-machine test (skipped by the owner).

