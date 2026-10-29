#!/usr/bin/env bash
#
# music.sh — MPD backend for modules/mpd (music, radio and the local files): Yandex
# Music likes (yandex-music-cli), internet radio (radio-cli stations) and the music
# folders (~/Music) in one player.
#
#   --status            {service, state, pos, length, elapsed, duration, random, repeat,
#                        file, title, artist, album, year, source, station, parked}
#                       state: "playing" | "paused" | "stopped"; parked: false, or the music a
#                       station put aside {pos, elapsed, duration, file, title, artist, album, year, length}
#   --listen            --status once per MPD event (polls while MPD is down)
#   --queue             [{pos, artist, title}]
#   --parked-queue      [{pos, artist, title}] of the music put aside ([] when none)
#   --stations          [{key, name, genre, about}]
#   --play [POS] | --pause | --stop | --toggle | --next | --prev | --seek SECONDS | --random
#   --on                start mpd.service and play: the music put aside, else the queue it kept,
#                       else the likes
#   --off               stop playback and mpd.service (the popup's switch)
#   --queue-del POS     take a track out of the queue
#   --repeat            cycle repeat: off -> all -> one -> off
#   --radio KEY         play a station; the music playing or paused is parked first: the whole
#                       player as it stood (queue, track, place) goes to one file, $PARKED
#   --unpark            bring the parked music back, at the track and the second it stopped at
#   --likes             rebuild the likes queue (manager.py --init)
#   --likes-at FILE     play a liked track by its file; the likes queue loads first when it is not in
#   --likes-refresh     rebuild the likes queue after an update, the playing track kept
#   --update            sync likes from Yandex (manager.py --update) -> {ok, message}
#   --files-play DIR [FILE]  the queue becomes every audio file under DIR (sorted, ~/Music/yandex
#                       left out), played from FILE (else the first); file:// URIs
#   --files-add FILE    a file to the end of the queue
#   --files-next FILE   a file after the playing one
#
# Commands that start playback launch mpd.service first when it is down. Commands that load
# other music (--likes, --likes-at, --files-play) drop the parked music: it is not coming back.
# source: "likes" | "radio" | "files" | "" (nothing queued). repeat: "off" | "all" | "one".

set -u

MANAGER="$HOME/.config/scripts/yandex-music/manager.py"
STATIONS="$HOME/.config/scripts/radio/stations.json"
YANDEX_DIR="$HOME/Music/yandex"
# the music a station took the queue from: {pos, elapsed, duration, file, title, artist, album,
# year, queue: [{pos, file, artist, title}]}; the only record of it (the shell reads it, --unpark
# restores it), so it outlives a restart of the shell or of MPD
PARKED="${XDG_STATE_HOME:-$HOME/.local/state}/music-parked.json"

ok()    { echo '{"ok":true}'; }
error() { jq -cn --arg e "$1" '{ok:false, error:$e}'; }

mpd_up() {
    mpc status >/dev/null 2>&1 && return
    systemctl --user start mpd
    for _ in 1 2 3 4 5 6 7 8 9 10; do mpc status >/dev/null 2>&1 && return; sleep 0.2; done
}

cmd_status() {
    local status current
    if ! status=$(mpc status $'%state%\t%songpos%\t%length%\t%currenttime%\t%totaltime%\t%random%\t%repeat%\t%single%' 2>/dev/null); then
        echo '{"service":false}'
        return
    fi
    current=$(mpc current -f $'%file%\t%title%\t%artist%\t%album%\t%date%\t%name%')
    local parked=""
    [[ -f "$PARKED" ]] && parked=$(jq -c '.length = (.queue | length) | del(.queue)' "$PARKED" 2>/dev/null)
    jq -cn --arg status "$status" --arg current "$current" --argjson parked "${parked:-false}" --slurpfile stations "$STATIONS" '
        def seconds: split(":") | map(tonumber? // 0) | reduce .[] as $p (0; . * 60 + $p);
        ($status | split("\t")) as $s
        | ($current | split("\t")) as $c
        | ($stations[0] // {} | to_entries | map(select(.value.url == ($c[0] // ""))) | first) as $station
        | {
            service: true,
            parked: $parked,
            state: $s[0], pos: ($s[1] | tonumber? // 0), length: ($s[2] | tonumber? // 0),
            elapsed: ($s[3] // "0" | seconds), duration: ($s[4] // "0" | seconds),
            random: ($s[5] == "on"),
            repeat: (if $s[6] != "on" then "off" elif $s[7] == "on" then "one" else "all" end),
            file: ($c[0] // ""),
            title: (if ($c[1] // "") != "" or (($c[0] // "") | (startswith("/") or startswith("file://")) | not)
                    then ($c[1] // "") else (($c[0] | split("/") | last) | sub("\\.[^.]+$"; "")) end),
            artist: ($c[2] // ""),
            album: ($c[3] // ""), year: ($c[4] // "" | .[0:4]),
            source: (if $station then "radio"
                     elif (($c[0] // "") | startswith("/") or startswith("file://")) then "files"
                     elif ($c[0] // "") != "" then "likes" else "" end),
            station: ($station.value.name // ($c[5] // ""))
          }'
}

# One connection for all events (mpc idleloop): a `mpc idle` per event lost what happened
# between two of them (a station starting right after the clear showed as stopped). Ends with
# the shell that started it or when its stdout closes (listen.sh); polls while MPD is down.
cmd_listen() {
    local prev="" out parent=$PPID
    ok() {                                      # listen_to calls it once per event
        out=$(cmd_status)
        [[ "$out" == "$prev" ]] && return
        echo "$out" || return
        prev=$out
    }
    . "${BASH_SOURCE[0]%/*}/listen.sh"
    trap '' PIPE
    while kill -0 "$parent" 2>/dev/null; do
        ok || return
        listen_to mpc idleloop player playlist options
        mpc status >/dev/null 2>&1 || sleep 2
    done
}

cmd_repeat() {
    case "$(mpc status $'%repeat%\t%single%')" in
        off*)        mpc -q repeat on;  mpc -q single off ;;
        $'on\toff') mpc -q single on ;;
        *)           mpc -q repeat off; mpc -q single off ;;
    esac
    ok
}

# The music in the queue (playing or paused), put aside for a station: the whole player as it
# stood — the queue with each track's tags, the track and the second — in one file of ours
# (MPD may have stored playlists off). A station in the queue already: the music is parked.
park_music() {
    local file place
    file=$(mpc current -f '%file%' 2>/dev/null)
    [[ -z "$file" ]] && return
    jq -e --arg f "$file" 'any(.[]; .url == $f)' "$STATIONS" >/dev/null 2>&1 && return
    place=$(mpc status $'%songpos%\t%currenttime%' | head -1) || return
    mkdir -p "$(dirname "$PARKED")"
    mpc playlist -f $'%position%\t%file%\t%title%\t%artist%\t%album%\t%date%\t%time%' |
        jq -Rs --arg place "$place" '
            def seconds: split(":") | map(tonumber? // 0) | reduce .[] as $p (0; . * 60 + $p);
            ($place | split("\t")) as $at
            | [split("\n")[] | select(length > 0) | split("\t")
               | {pos: (.[0] | tonumber), file: .[1],
                  title: (if (.[2] // "") != "" then .[2] else (.[1] | split("/") | last | sub("\\.[^.]+$"; "")) end),
                  artist: (.[3] // ""), album: (.[4] // ""), year: (.[5] // "" | .[0:4]), duration: (.[6] // "" | seconds)}] as $queue
            | ($at[0] | tonumber? // 1) as $pos
            | ($queue[$pos - 1] // $queue[0]) as $track
            | $track + {elapsed: ($at[1] // "0" | seconds), queue: ($queue | map({pos, file, artist, title}))}
        ' > "$PARKED.tmp" && mv "$PARKED.tmp" "$PARKED"
}

cmd_unpark() {
    local place pos secs
    place=$(jq -r '"\(.pos)\t\(.elapsed)"' "$PARKED" 2>/dev/null) || { error "no music was put aside"; return; }
    IFS=$'\t' read -r pos secs <<<"$place"
    mpd_up
    mpc -q clear && jq -r '.queue[].file' "$PARKED" | mpc -q add || { error "could not bring the music back"; return; }
    mpc -q play "$pos" && mpc -q seek "$secs" 2>/dev/null
    rm -f "$PARKED"
    ok
}

# other music takes the queue: the parked music is not coming back
drop_parked() { rm -f "$PARKED"; }

cmd_radio() {
    local url
    url=$(jq -r --arg k "$1" '.[$k].url // empty' "$STATIONS")
    [[ -z "$url" ]] && { error "unknown station"; return; }
    mpd_up
    park_music
    mpc -q clear && mpc -q add "$url" && mpc -q play && ok || error "could not start the station"
}

# position of FILE in the current queue, empty when it is not there
queue_pos() {
    mpc playlist -f $'%position%\t%file%' 2>/dev/null | awk -F'\t' -v f="$1" '$2 == f { print $1; exit }'
}

# audio files under DIR, sorted, Yandex Music's folder left out (NUL-separated)
files_in() {
    find "$1" -path "$YANDEX_DIR" -prune -o -type f \( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.ogg' \
        -o -iname '*.opus' -o -iname '*.m4a' -o -iname '*.wav' -o -iname '*.aac' \) -print0 | sort -zV
}

# the queue becomes the folder's tracks and plays from FILE (else the first one)
cmd_files_play() {
    local dir file pos=1 i
    dir=$(realpath -e -- "${1:-}" 2>/dev/null) || { error "no such folder"; return; }
    local -a list uris
    mapfile -d '' -t list < <(files_in "$dir")
    (( ${#list[@]} )) || { error "no music in this folder"; return; }
    if [[ -n "${2:-}" ]]; then
        file=$(realpath -e -- "$2" 2>/dev/null) || { error "no such file"; return; }
        for i in "${!list[@]}"; do [[ "${list[i]}" == "$file" ]] && pos=$((i + 1)); done
    fi
    for file in "${list[@]}"; do uris+=("file://$file"); done
    mpd_up
    drop_parked
    mpc -q clear && mpc -q add "${uris[@]}" && mpc -q play "$pos" && ok || error "could not play the folder"
}

cmd_likes_at() {
    local file=$1 pos
    pos=$(queue_pos "$file")
    if [[ -z "$pos" ]]; then
        mpd_up
        drop_parked
        uv run --script "$MANAGER" --init >/dev/null 2>&1 || { error "could not load likes"; return; }
        pos=$(queue_pos "$file")
    fi
    [[ -z "$pos" ]] && { error "not in the likes"; return; }
    mpc -q play "$pos" && ok || error "could not play the track"
}

# the likes queue rebuilt after an update (manager --init would start it from the
# first track): the same tracks in the same order, the playing one kept at its
# place. A radio station playing is left alone.
cmd_likes_refresh() {
    local file elapsed status music="$HOME/Music/yandex"
    mpc status >/dev/null 2>&1 || { ok; return; }
    file=$(mpc current -f '%file%')
    [[ "$file" == http* ]] && { ok; return; }
    status=$(mpc status '%state%')
    elapsed=$(mpc status '%currenttime%' | awk -F: '{ s = 0; for (i = 1; i <= NF; i++) s = s * 60 + $i; print s }')
    local -a tracks
    mapfile -t tracks < <(
        { jq -r '.ids | to_entries | sort_by(.value.index) | .[].value.file' "$HOME/.config/scripts/yandex-music/state.json" 2>/dev/null
          find "$music" -maxdepth 1 -name '*.mp3' -printf '%f\n'; } | awk '!seen[$0]++' |
        while IFS= read -r f; do [[ -f "$music/$f" ]] && printf '%s\n' "$f"; done)
    mpc -q clear
    (( ${#tracks[@]} )) && mpc -q add "${tracks[@]}"
    [[ "$status" == stop || -z "$file" ]] && { ok; return; }
    local pos; pos=$(queue_pos "$file")
    [[ -z "$pos" ]] && { ok; return; }
    mpc -q play "$pos"
    mpc -q seek "$elapsed"
    [[ "$status" == pause ]] && mpc -q pause
    ok
}

cmd_update() {
    local out
    if out=$(uv run --script "$MANAGER" --update 2>&1); then
        jq -cn --arg m "$(grep -m1 'Total likes' <<<"$out" | sed 's/^\[\*\] //')" '{ok:true, message:$m}'
    else
        error "$(grep -m1 '\[!\]' <<<"$out" | sed 's/^\[!\] //')"
    fi
}

case "${1:-}" in
    --status)   cmd_status ;;
    --listen)   cmd_listen ;;
    --parked-queue) if [[ -f "$PARKED" ]]; then jq -c '.queue | map({pos, artist, title})' "$PARKED"; else echo '[]'; fi ;;
    --queue)    mpc playlist -f $'%position%\t%artist%\t%title%\t%file%' |
                    jq -Rcs 'split("\n") | map(select(length > 0) | split("\t")
                             | {pos: (.[0] | tonumber), artist: .[1],
                                title: (if .[2] != "" then .[2] else (.[3] | split("/") | last) end)})' ;;
    --stations) jq -c 'to_entries | map({key, name: .value.name, genre: (.value.genre // ""), about: (.value.about // "")})' "$STATIONS" ;;
    --on)       mpd_up
                if [[ -f "$PARKED" ]]; then cmd_unpark
                elif [[ -n "$(mpc playlist 2>/dev/null)" ]]; then mpc -q play && ok
                elif [[ -f "$MANAGER" ]]; then uv run --script "$MANAGER" --init >/dev/null 2>&1 && ok || error "could not load likes"
                else error "nothing to play: pick something in Library"; fi ;;
    --off)      mpc -q stop 2>/dev/null; systemctl --user stop mpd && ok || error "could not stop mpd" ;;
    --queue-del) mpc -q del "${2:-}" && ok || error "could not remove it" ;;
    --play)     mpd_up; mpc -q play ${2:+"$2"} && ok ;;
    --pause)    mpc -q pause && ok ;;
    --stop)     mpc -q stop && ok ;;
    --toggle)   mpc -q toggle && ok ;;
    --next)     mpc -q next && ok ;;
    --prev)     mpc -q prev && ok ;;
    --seek)     mpc -q seek "${2:-0}" && ok ;;
    --random)   mpc -q random && ok ;;
    --repeat)   cmd_repeat ;;
    --radio)    cmd_radio "${2:-}" ;;
    --unpark)   cmd_unpark ;;
    --likes)    mpd_up; drop_parked; uv run --script "$MANAGER" --init >/dev/null 2>&1 && ok || error "could not load likes" ;;
    --likes-at) cmd_likes_at "${2:-}" ;;
    --likes-refresh) cmd_likes_refresh ;;
    --files-play) cmd_files_play "${2:-}" "${3:-}" ;;
    --files-add) mpc -q add "file://$(realpath -e -- "${2:-}")" && ok || error "could not add it" ;;
    --files-next) mpc -q insert "file://$(realpath -e -- "${2:-}")" && ok || error "could not add it" ;;
    --update)   cmd_update ;;
    *)          error "unknown command: ${1:-}" ;;
esac
