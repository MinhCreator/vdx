#!/usr/bin/env -S uv run --script
# /// script
# dependencies = ["yandex-music"]
# ///
"""yandex_likes.py — like state of local Yandex Music tracks for plugins/music.

    --likes       {ok, liked: [id], files: {file: id}}
    --like ID     {ok}
    --unlike ID   {ok}

Reads the token and state.json of yandex-music-cli (~/.config/scripts/yandex-music);
an unliked track stays local until the next `music --update` removes it.
"""

import json
import sys
from pathlib import Path

from yandex_music import Client

HOME = Path.home() / ".config" / "scripts" / "yandex-music"


def reply(**fields) -> None:
    print(json.dumps(fields, ensure_ascii=False))


def main() -> None:
    command, arg = (sys.argv + [None, None])[1:3]
    try:
        client = Client((HOME / "token").read_text().strip()).init()
        if command == "--likes":
            state = json.loads((HOME / "state.json").read_text()).get("ids", {})
            liked = [str(t.id) for t in client.users_likes_tracks().tracks]
            reply(ok=True, liked=liked, files={meta["file"]: tid for tid, meta in state.items()})
        elif command == "--like" and arg:
            client.users_likes_tracks_add(arg)
            reply(ok=True)
        elif command == "--unlike" and arg:
            client.users_likes_tracks_remove(arg)
            reply(ok=True)
        else:
            reply(ok=False, error=f"unknown command: {command}")
    except Exception as e:
        reply(ok=False, error=str(e).splitlines()[0][:120] if str(e) else type(e).__name__)


if __name__ == "__main__":
    main()
