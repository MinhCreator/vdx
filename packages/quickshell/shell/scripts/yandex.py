#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["yandex-music"]
# ///
"""yandex.py — Yandex Music online: likes, search, playlists and covers, for the
music module (modules/yandex) and the Yandex Music app (apps/yandex).

    --likes                     {ok, liked: [id], files: {file: id}}   the module's state
    --likes-list                {ok, tracks: [track]}                  every liked track
    --search TEXT               {ok, tracks: [track]}
    --like ID | --unlike ID     {ok}
    --cover ID                  {ok, path}          the track's cover, cached under ~/.cache
    --playlists                 {ok, playlists: [{kind, title, count}]}
    --playlist KIND             {ok, tracks: [track]}
    --playlist-create TITLE     {ok, kind}
    --playlist-rename KIND TITLE {ok}
    --playlist-delete KIND      {ok}
    --playlist-add KIND ID      {ok}     the track is added at the top
    --playlist-remove KIND INDEX {ok}    the track at INDEX (0 = first) goes

    track: {id, title, artist, album, album_id, duration}   duration in seconds

Reads the token and state.json of yandex-music-cli (~/.config/scripts/yandex-music);
an unliked track stays local until the next `music --update` removes it. Playback
is music.sh's (MPD), and only a track the update has downloaded can play.
"""

import json
import sys
import urllib.request
from pathlib import Path

from backend import fail, out
from yandex_music import Client

HOME = Path.home() / ".config" / "scripts" / "yandex-music"
CACHE = Path.home() / ".cache" / "quickshell" / "yandex"
SEARCH_LIMIT = 30


def client() -> Client:
    return Client((HOME / "token").read_text().strip()).init()


def track(t) -> dict:
    album = t.albums[0] if t.albums else None
    return {
        "id": str(t.id),
        "title": t.title or "",
        "artist": ", ".join(a.name for a in (t.artists or [])),
        "album": album.title if album else "",
        "album_id": str(album.id) if album else "",
        "duration": round((t.duration_ms or 0) / 1000),
    }


def tracks(c: Client, ids: list) -> list[dict]:
    return [track(t) for t in c.tracks(ids)] if ids else []


def cover(c: Client, track_id: str) -> str:
    """The track's 400 px cover, downloaded once; the path of the file."""
    path = CACHE / f"{track_id}.jpg"
    if not path.is_file() or path.stat().st_size == 0:
        found = c.tracks([track_id])
        uri = found[0].cover_uri if found else None
        if not uri:
            raise ValueError("no cover")
        CACHE.mkdir(parents=True, exist_ok=True)
        data = urllib.request.urlopen("https://" + uri.replace("%%", "400x400"), timeout=10).read()
        path.write_bytes(data)
    return str(path)


def playlist(c: Client, kind: str):
    return c.users_playlists(kind)


def main() -> None:
    command, args = (sys.argv[1] if len(sys.argv) > 1 else ""), sys.argv[2:]
    try:
        c = client()
        if command == "--likes":
            state = json.loads((HOME / "state.json").read_text()).get("ids", {}) if (HOME / "state.json").exists() else {}
            liked = [str(t.id) for t in c.users_likes_tracks().tracks]
            out({"ok": True, "liked": liked, "files": {meta["file"]: tid for tid, meta in state.items()}})
        elif command == "--likes-list":
            ids = [t.id for t in c.users_likes_tracks().tracks]
            out({"ok": True, "tracks": tracks(c, ids)})
        elif command == "--search" and len(args) == 1:
            found = c.search(args[0], type_="track")
            results = found.tracks.results[:SEARCH_LIMIT] if found and found.tracks else []
            out({"ok": True, "tracks": [track(t) for t in results]})
        elif command in ("--like", "--unlike") and len(args) == 1:
            (c.users_likes_tracks_add if command == "--like" else c.users_likes_tracks_remove)(args[0])
            out({"ok": True})
        elif command == "--cover" and len(args) == 1:
            out({"ok": True, "path": cover(c, args[0])})
        elif command == "--playlists":
            out({"ok": True, "playlists": [
                {"kind": str(p.kind), "title": p.title or "", "count": p.track_count or 0}
                for p in c.users_playlists_list()]})
        elif command == "--playlist" and len(args) == 1:
            out({"ok": True, "tracks": tracks(c, [t.id for t in playlist(c, args[0]).tracks])})
        elif command == "--playlist-create" and len(args) == 1:
            created = c.users_playlists_create(args[0])
            out({"ok": True, "kind": str(created.kind)})
        elif command == "--playlist-rename" and len(args) == 2:
            playlist(c, args[0]).rename(args[1])
            out({"ok": True})
        elif command == "--playlist-delete" and len(args) == 1:
            c.users_playlists_delete(args[0])
            out({"ok": True})
        elif command == "--playlist-add" and len(args) == 2:
            target = playlist(c, args[0])
            found = c.tracks([args[1]])
            album_id = found[0].albums[0].id
            target.insert_track(args[1], album_id)
            out({"ok": True})
        elif command == "--playlist-remove" and len(args) == 2:
            index = int(args[1])
            playlist(c, args[0]).delete_tracks(index, index + 1)
            out({"ok": True})
        else:
            fail(f"unknown command: {command}")
    except SystemExit:
        raise
    except Exception as e:
        fail(str(e).splitlines()[0][:120] if str(e) else type(e).__name__)


if __name__ == "__main__":
    main()
