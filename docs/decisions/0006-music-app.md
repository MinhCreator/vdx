# 0006 — Music: one bar module, a window tabbed by source

Status: Accepted 2026-10-20 (the owner's design, in chat; the look reworked on the owner's
checks, see Verification).
Phase: tasks/09_MUSIC_SUBSYSTEM.md › Part D

## Context

The bar had three music modules (`player`, `yandex`, `radio`), each with its own
popup and its own transport. The Music window repeated all of them on four pages
(Now playing, Likes, Search, Playlist, Stations), and the Settings had four music
pages. The rule was unclear: which one plays, which one shows, which one picks.
Local folders were not a source at all.

## Decision

- The bar shows what plays now. One bar module, `music` (replaces `player`, `yandex`,
  `radio`; `BarLayout.renamed` maps the old ids). Its face is the track of
  `PlayerService`, any source. Click opens the popup, middle click plays or pauses.
- The window picks what to play. Sources, always in this order: Yandex Music, Files,
  Radio. Each is a tab (KitChoices in the sidebar, stretched). A tab shows only while
  its component is installed; with none, the window says to install the mpd component.
- Popup (`modules/music/`): header with the state, the window's button and a switch:
  the music service (MPD) on or off (`music.sh --on` starts mpd.service and plays the
  queue it kept, else the likes; `--off` stops playback and mpd.service). The switch
  follows the flip at once (`wanted`) until MPD gets there. Off, the popup shows only
  that it is off. Tabs Now playing, Queue, Library. Queue is MPD's queue (Yandex,
  files) and is hidden while a browser or the radio is the player. Now playing ends
  with a full-width select of the players when several run (any number fits).
  Library is quick picks as tiles (`MusicTile`), each source while installed: the
  Yandex likes (one wide tile), the folders of `music.folders` and the favourite
  stations, two to a row; "Open Music" at the foot for the rest.
- Players shown (`music.players`): all (default), music (MPD only) or pick (every
  player but `music.hiddenPlayers`, by name). The filter is in `PlayerService.sources`,
  so the bar face, the popup and the island agree. The pick list is the players
  running now plus the ones hidden before.
- Favourite stations: `music.favoriteStations` (station keys), a star in the stations
  table, All stations / Favourites in the Radio tab's sidebar. Stations carry `genre`
  and `about` (radio-cli `stations.json`; `music.sh --stations`), shown as columns.
- Window (`apps/music/`): tabs by source. Yandex Music: Likes, Search, Playlists (+ New
  playlist). Files: the folders of `music.folders` in the sidebar, the page lists a folder
  (subfolders first, click enters, Up in the header) then its tracks; a click plays the
  folder from that track; ⋮ has Play, Play next, Add to queue. Radio: the stations table.
  The player bar stays at the foot of every tab.
- Local files are an MPD source. `scripts/music_files.py --list DIR` lists a folder
  (audio by extension, natural sort, `~/Music/yandex` left out). `music.sh --files-play
  DIR [FILE]` makes the queue of the folder's files as `file://` URIs over MPD's local
  socket and plays from FILE. `--files-add` / `--files-next` serve the menu. A file
  playing has a `/` or `file://` path, so `source` is `files`.
- Sections: `BarLayout.sections` = files, yandex, radio. They are the music sources a
  component brings, not bar modules; `installer/check.py` accepts a component's
  `modules` naming either. `components.toml`: mpd → files, yandex-music → yandex,
  radio → radio. `MpdService.needed` = files installed (the others require mpd).
- Settings: one page, `modules/music/MusicSettings.qml`: BAR (Shows, Max length),
  PLAYER (Time left), PLAYERS (Show: All players / Music only / Pick, the switches), WINDOW (Opens on: Last tab / Yandex / Files / Radio; Close when a
  track plays), FILES (the folders). Options are `music.*` in `modules.json`.
- Migration version 7 (`settings_migrate.py`, `to_7`): layout ids player/yandex/radio →
  music (first position kept, no repeats); `music.show` / `titleLength` from yandex,
  else player, else radio; `opensOn` likes → yandex, playing → last.
- IPC `music`: `toggle|open|close`, `go <tab>` with `yandex|files|radio`. The old pages
  `likes|search|playlist` open the Yandex tab (`playlist` shows the playlist the popup
  loaded, else a prompt to pick one); `playing` keeps the tab shown. `music.opensOn`
  picks the tab on open (`last` keeps the one shown); `music.closeOnPlay` closes the
  window after a click plays.
- Playback and its limits stay as decision 0004 says (Yandex tracks play once the update
  has downloaded them). Services stay in their folders (`modules/mpd`, `modules/yandex`,
  `modules/radio`, `modules/player`).

## Consequences

- Removed: the Player, Yandex and Radio bar modules and their popups and settings pages,
  `apps/music/MusicNowPlaying.qml` (the popup has the same look for any source).
- The window's Yandex tab reads `YandexLibrary` / `YandexService`, the Files tab
  `music_files.py`, the Radio tab `RadioService`: each only while installed.
- Tab labels are short: "Yandex" (the full name does not fit an equal-width row in the
  sidebar); the window's Yandex tab is still the Yandex Music source.
- A folder is listed by a process per open and per folder change; nothing polls.

## Verification

Checked: `./install.py check` (see the report of the change); the shell restarted with
no QML errors; the window opens on each tab (screenshots in the change's report);
`ipc call music go yandex|files|radio|likes|search|playlist|playing` and `close` work;
the Files tab lists folders and tracks of a scratch folder, and a subfolder's Up row
depends on a click path that was not drivable here.
Later: the owner checked the popup and the window and asked for the switch, the
player select, the Queue tab only for MPD, the Library tiles (prototype screenshot),
favourite stations and the players filter; the switch's off and on were run against
the live MPD, the filter's "music" against a playing browser.
Not done: clicks on the Library tiles, the star and the Pick switches by the agent; clicks through the
Files tab (enter, Up, play from a track, the ⋮ menu) and the Yandex search and playlists
on screen; the empty state with no source installed (not toggled on this machine); the
fresh-machine run (`tests/fresh-machine.sh`).
