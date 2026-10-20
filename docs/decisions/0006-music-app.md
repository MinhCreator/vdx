# 0006 — Music app: one player, Yandex Music and radio as sections

Status: Proposed (2026-10-20; the owner asked for it in chat: "an app Music with a
section for Yandex Music … in general a music player", the look waits for approval)
Phase: tasks/09_MUSIC_SUBSYSTEM.md › Part D

## Context

The Yandex Music window (`apps/yandex`, decision 0004) was a 640 px window of its own
look: tabs (Queue, Likes, Search, Playlists), a "full mode" toggle and a box with the
track at the bottom; it drove MPD only and was "not installed" without the
`yandex-music` component. Every other player (Spotify, a browser, mpv, the radio) had
only the Player popup. The other apps (Files, Shell Manager) have moved to one look: a
sidebar pane with its header and sections, the page's list as a table in a raised box.

## Options

1. Restyle the Yandex window, keep it Yandex-only. The rest of the music stays in popups.
2. One Music app (core, always installed) on `PlayerService`; Yandex Music and the
   radio as sidebar sections shown while their components are installed.
3. Separate windows per provider (Yandex, radio) beside a generic player window.

## Decision: option 2

- App id `music`, IPC `music` (`toggle|open|close`, `go <page>`), window 1000 × 660,
  bar module `player` (its options under Bar modules, the link row in Apps).
- Layout as Files: sidebar (LISTEN › Now playing; YANDEX MUSIC › Likes, Search,
  PLAYLISTS + New playlist; RADIO › Stations), the page's header and field, the list
  as a table in a raised box (#, title and artist, album, time, like, ⋮), the player
  bar at the foot (any player, through `PlayerService`). Now playing shows the player
  large, a choice of players when several run, and MPD's queue (UP NEXT) while the
  likes play.
- A section's data (`YandexLibrary`, `YandexService`, `RadioService`) is read only
  while `BarLayout.installed` says its component is on; nothing polls otherwise.
- Playback and its limits stay as decision 0004 says (MPD, a track plays once the
  update has downloaded it). `YandexLibrary` moves to `modules/yandex/`.
- Sidebar rows are shared with Files: `kit/KitSideRow`, `kit/KitSideCaption`.
- Options move from `yandex` to `music` (`opensOn`, `showRemaining`, `closeOnPlay`;
  `settings_migrate.py` version 6, tested); the bar module's stay under `yandex`.

## Consequences

- IPC `yandex-music` is gone; the Yandex popup's button opens `music go likes`.
- The Yandex popup keeps its own player (`YandexNowPlaying`, `YandexQueue`); moving
  it onto `PlayerService` is left for later.
- Local files (outside `~/Music/yandex`) are not a library yet: MPD's music dir is the
  submodule's, and MPD is not installed by default.

## Verification

`./install.py check` green; `tests/test_settings_migrate.py` (16 tests); the shell
restarted with a clean log; the window opened on Now playing with a browser's
MPRIS player, the Yandex section and the playlists drawn (screenshot). Not done: the
owner's look approval, clicks through Likes, Search, a playlist and Stations.
