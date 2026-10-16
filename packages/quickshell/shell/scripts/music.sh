#!/usr/bin/env bash
#
# music.sh — MPD backend for modules/mpd (music and radio): Yandex Music likes
# (yandex-music-cli) and internet radio (radio-cli stations) in one player.
#
#   --status            {service, state, pos, length, elapsed, duration, random, repeat,
#                        file, title, artist, album, year, source, station}
#   --listen            --status once per MPD event (polls while MPD is down)
#   --queue             [{pos, artist, title}]
#   --stations          [{key, name}]
#   --cover FILE        {ok, path}       embedded cover, cached under ~/.cache
#   --play [POS] | --pause | --stop | --toggle | --next | --prev | --seek SECONDS | --random
#   --repeat            cycle repeat: off -> all -> one -> off
#   --radio KEY         play a station
#   --likes             rebuild the likes queue (manager.py --init)
#   --update            sync likes from Yandex (manager.py --update) -> {ok, message}
#
# Commands that start playback launch mpd.service first when it is down.
# source: "likes" | "radio" | "" (nothing queued). repeat: "off" | "all" | "one".

set -u

MANAGER="$HOME/.config/scripts/yandex-music/manager.py"
STATIONS="$HOME/.config/scripts/radio/stations.json"
COVERS="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/music"

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
    jq -cn --arg status "$status" --arg current "$current" --slurpfile stations "$STATIONS" '
        def seconds: split(":") | map(tonumber? // 0) | reduce .[] as $p (0; . * 60 + $p);
        ($status | split("\t")) as $s
        | ($current | split("\t")) as $c
        | ($stations[0] // {} | to_entries | map(select(.value.url == ($c[0] // ""))) | first) as $station
        | {
            service: true,
            state: $s[0], pos: ($s[1] | tonumber? // 0), length: ($s[2] | tonumber? // 0),
            elapsed: ($s[3] // "0" | seconds), duration: ($s[4] // "0" | seconds),
            random: ($s[5] == "on"),
            repeat: (if $s[6] != "on" then "off" elif $s[7] == "on" then "one" else "all" end),
            file: ($c[0] // ""), title: ($c[1] // ""), artist: ($c[2] // ""),
            album: ($c[3] // ""), year: ($c[4] // "" | .[0:4]),
            source: (if $station then "radio" elif ($c[0] // "") != "" then "likes" else "" end),
            station: ($station.value.name // ($c[5] // ""))
          }'
}

cmd_listen() {
    local prev="" out
    while :; do
        out=$(cmd_status)
        [[ "$out" != "$prev" ]] && { echo "$out"; prev=$out; }
        mpc idle player playlist options >/dev/null 2>&1 || sleep 2
    done
}

cmd_cover() {
    local file=$1 path
    path="$COVERS/$(printf '%s' "$file" | md5sum | cut -c1-16).jpg"
    if [[ ! -s "$path" ]]; then
        mkdir -p "$COVERS"
        mpc readpicture "$file" > "$path" 2>/dev/null
        [[ -s "$path" ]] || { rm -f "$path"; error "no cover"; return; }
    fi
    jq -cn --arg p "$path" '{ok:true, path:$p}'
}

cmd_repeat() {
    case "$(mpc status $'%repeat%\t%single%')" in
        off*)        mpc -q repeat on;  mpc -q single off ;;
        $'on\toff') mpc -q single on ;;
        *)           mpc -q repeat off; mpc -q single off ;;
    esac
    ok
}

cmd_radio() {
    local url
    url=$(jq -r --arg k "$1" '.[$k].url // empty' "$STATIONS")
    [[ -z "$url" ]] && { error "unknown station"; return; }
    mpd_up
    mpc -q clear && mpc -q add "$url" && mpc -q play && ok || error "could not start the station"
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
    --queue)    mpc playlist -f $'%position%\t%artist%\t%title%' |
                    jq -Rcs 'split("\n") | map(select(length > 0) | split("\t")
                             | {pos: (.[0] | tonumber), artist: .[1], title: .[2]})' ;;
    --stations) jq -c 'to_entries | map({key, name: .value.name})' "$STATIONS" ;;
    --cover)    cmd_cover "${2:-}" ;;
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
    --likes)    mpd_up; uv run --script "$MANAGER" --init >/dev/null 2>&1 && ok || error "could not load likes" ;;
    --update)   cmd_update ;;
    *)          error "unknown command: ${1:-}" ;;
esac
