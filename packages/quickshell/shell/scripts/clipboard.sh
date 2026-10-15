#!/usr/bin/env bash
#
# clipboard.sh — clipboard history kept as plain files (text or PNG), newest
# first, so an image can be dragged straight out of the list.
#   watch            run `wl-paste --watch … store` (one per session: a lock)
#   store            stdin = the new selection (run by the watcher)
#   list             [{"id": "...", "kind": "text|image", "preview": "...", "path": "...", "time": 1700000000}, ...]
#   copy <id>        put the entry back on the clipboard (and on top)
#   delete <id>      {"ok": true}
#   clear            {"ok": true}
#   limit <n>        keep at most n entries, {"ok": true}
# Entries: $XDG_DATA_HOME/clipboard/<epoch-ns>-<hash>.{txt,png}; the limit in
# its `limit` file (100 by default). Password-manager copies are not kept.

set -u
dir="${XDG_DATA_HOME:-$HOME/.local/share}/clipboard"
mkdir -p "$dir"

limit() { cat "$dir/limit" 2>/dev/null || echo 100; }

# drop the oldest entries beyond the limit
trim() {
  ls -1t "$dir"/*.txt "$dir"/*.png 2>/dev/null | tail -n +"$(( $(limit) + 1 ))" | xargs -r rm -f
}

entry() { ls -1 "$dir"/*-"$1".* 2>/dev/null | head -1; }

case "${1:-}" in
  watch)
    # a second watcher (an old shell's, not yet gone) would store everything twice
    exec flock -n "$dir/.watch.lock" wl-paste --watch bash "$0" store
    ;;
  store)
    exec 9>"$dir/.store.lock"
    flock 9
    types=$(wl-paste --list-types 2>/dev/null)
    grep -q 'x-kde-passwordManagerHint' <<<"$types" && exit 0
    tmp=$(mktemp)
    cat >"$tmp"
    [ -s "$tmp" ] || { rm -f "$tmp"; exit 0; }
    if grep -q '^image/png' <<<"$types" && ! grep -q '^text/' <<<"$types"; then ext=png; else ext=txt; fi
    hash=$(sha1sum "$tmp" | cut -c1-16)
    rm -f "$dir"/*-"$hash".*                       # a repeat moves to the top
    mv "$tmp" "$dir/$(date +%s%N)-$hash.$ext"
    trim
    echo stored
    ;;
  list)
    ls -1t "$dir"/*.txt "$dir"/*.png 2>/dev/null | while read -r f; do
      name=${f##*/}; id=${name%.*}; id=${id#*-}
      if [[ $f == *.png ]]; then
        jq -cn --arg id "$id" --arg path "$f" --argjson t "$(stat -c %Y "$f")" \
          '{id: $id, kind: "image", preview: "", path: $path, time: $t}'
      else
        head -c 400 "$f" | jq -cRs --arg id "$id" --arg path "$f" --argjson t "$(stat -c %Y "$f")" \
          '{id: $id, kind: "text", preview: ., path: $path, time: $t}'
      fi
    done | jq -cs .
    ;;
  copy)
    f=$(entry "$2"); [ -n "$f" ] || { echo '{"ok":false,"error":"no such entry"}'; exit 0; }
    if [[ $f == *.png ]]; then wl-copy --type image/png <"$f"; else wl-copy <"$f"; fi
    echo '{"ok":true}'
    ;;
  delete)
    f=$(entry "$2"); [ -n "$f" ] && rm -f "$f"
    echo '{"ok":true}'
    ;;
  clear)
    rm -f "$dir"/*.txt "$dir"/*.png
    echo '{"ok":true}'
    ;;
  limit)
    [[ ${2:-} =~ ^[0-9]+$ ]] || { echo '{"ok":false,"error":"limit must be a number"}'; exit 0; }
    echo "$2" >"$dir/limit"
    trim
    echo '{"ok":true}'
    ;;
  *)
    echo '{"ok":false,"error":"usage: clipboard.sh store|list|copy <id>|delete <id>|clear|limit <n>"}'
    ;;
esac
