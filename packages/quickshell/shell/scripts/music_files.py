#!/usr/bin/env python3
"""music_files — the local music folders of the music module (modules/music): the
folders and the tracks directly in one of them. Playback is music.sh's (--files-play).

    --list DIR        {"ok", "dirs": [{name, path}], "tracks": [{path, title, artist}]}

Audio by extension (mp3 flac ogg opus m4a wav aac); a title "Artist - Title" from the
file name is split when it has the " - "; natural sort. ~/Music/yandex is Yandex
Music's own folder (MPD's) and is left out."""
import re
import sys
from pathlib import Path

from backend import fail, out

AUDIO = {".mp3", ".flac", ".ogg", ".opus", ".m4a", ".wav", ".aac"}
YANDEX = Path.home() / "Music" / "yandex"


def natural(name: str) -> list:
    return [int(t) if t.isdigit() else t.lower() for t in re.split(r"(\d+)", name)]


def track(path: Path) -> dict:
    artist, sep, title = path.stem.partition(" - ")
    if not sep:
        artist, title = "", path.stem
    return {"path": str(path), "title": title.strip(), "artist": artist.strip()}


def listing(folder: Path) -> dict:
    entries = sorted(folder.iterdir(), key=lambda p: natural(p.name))
    dirs = [{"name": p.name, "path": str(p)} for p in entries
            if p.is_dir() and not p.name.startswith(".") and p != YANDEX]
    tracks = [track(p) for p in entries if p.is_file() and p.suffix.lower() in AUDIO]
    return {"ok": True, "dirs": dirs, "tracks": tracks}


def main(argv: list[str]) -> None:
    if len(argv) != 3 or argv[1] != "--list":
        fail("usage: music_files.py --list DIR")
    folder = Path(argv[2]).expanduser()
    if not folder.is_dir():
        fail(f"no such folder: {argv[2]}")
    try:
        out(listing(folder))
    except OSError as e:
        fail(str(e))


if __name__ == "__main__":
    main(sys.argv)
