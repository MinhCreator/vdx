# 0004 — Yandex Music app: scope, playback and backend

Status: Accepted (2026-10-20, owner, chat: "делаем все кроме теста на free machine, приступай к приложению")
Phase: tasks/09_MUSIC_SUBSYSTEM.md › Part C
The window, its id and IPC: replaced by the Music app ([0006](0006-music-app.md), proposed).

## Context

The module (`modules/yandex`) plays the liked tracks that yandex-music-cli has
downloaded into `~/Music/yandex`, through MPD. The library (`yandex-music`,
unofficial, MarshalX) can also search, read playlists and change likes, but it
cannot stream a track to MPD in this setup: playback of a track needs the file
the update downloaded. No official public API is known (task 09, Part C).

## Options

1. Stream every search result and playlist track into MPD. Needs stream URLs
   and their tokens from the library and a second download path; a new engine.
2. Library and online list in the app; a track plays once the update has
   downloaded it, and the app says so. Playback stays in MPD.
3. A read-only app (liked tracks only). Cheapest, but search and playlists are
   the reason for an app.

## Decision: option 2

- Playback stays in MPD (one audio engine, as task 09 forbids a second). A
  liked track plays on a click once it is downloaded; a search or playlist track
  is listed with "not downloaded yet" until the update brings it. The app's
  Update button runs the same sync as `music --update`.
- Tabs: Likes (every liked track, an unlike hides it at once), Search (Enter),
  Playlists (a list, then its tracks). Each row has the like.
- The backend is `scripts/yandex.py` (was `yandex_likes.py`): one JSON reply per
  command, the module's `--likes` kept. Its ownership is the `yandex-music`
  component (`components.toml`, `links`), so it is linked only with that
  component; the app shows "not installed" without it.
- `music.sh --likes-at FILE` plays a liked track by its file, loading the likes
  queue first when it is not in the queue.
- The app and its bar module share the id `yandex` (the module's settings
  page is the app's `moduleSettings`); the app's IPC target is `yandex-music`.

## Consequences

- A search or playlist track cannot be played before the next update; the
  owner's sync decides when it is ready. Streaming is a later decision (a new
  record) if the owner wants it.
- The library is unofficial: an API change breaks the backend, not the shell
  (every command answers `{"ok": false, "error": …}`).
- Not in v1: playlist editing, queue of arbitrary tracks, app settings page.

## Verification

Live API read (likes, search, playlists) and each backend command against the
owner's account; `music.sh` queue lookup; the window opened and its rows drawn
(screenshot). Not done here: clicking through the search and playlist tabs, a
play from the app, the owner's look approval (design.md › new feature: prototype).
