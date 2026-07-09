#!/usr/bin/env bash
#
# media.sh — waybar media widget for MPD (local music + internet radio)
#
# MPD holds a single shared queue. This script never tracks state itself —
# it infers what's currently loaded by inspecting the queue on every call
# and comparing it against stations.json. One fact, one place to check it.
#
# Modes:
#   music — queue holds a local track
#   radio — queue holds a known radio stream (stations.json)
#   off   — MPD is unreachable, or the queue is empty
#
# Read-only widgets (JSON, wired to waybar `exec`):
#   -j, --title-json          now-playing text
#   --bracket-open-json       "["  — visible whenever mode != off
#   --bracket-close-json      "]"  — visible whenever mode != off
#   --prev-json               "prev" — visible only in music mode
#   --next-json               "next" — visible only in music mode
#   --status-json             play/pause icon — visible whenever mode != off
#   --kill-json               "kill" — visible whenever mode != off
#
# Actions (wired to waybar `on-click`):
#   -p, --prev                mpc prev
#   -n, --next                mpc next
#   -t, --toggle              mpc toggle
#   -k, --kill                stop + clear queue
#   -o, --open                open ncmpcpp if not already running

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

readonly PLAYER_COMMAND="kitty --class ncmpcpp -e ncmpcpp"
readonly STATIONS_FILE="$HOME/.config/scripts/radio/stations.json"
readonly ICON_PLAYING=""
readonly ICON_PAUSED=""

# ---------------------------------------------------------------------------
# MPD queries — raw facts, no interpretation.
# ---------------------------------------------------------------------------

mpd_available() {
    mpc >/dev/null 2>&1
}

mpd_playing() {
    [[ "$(mpc status 2>/dev/null | awk 'NR==2 {print $1}')" == "[playing]" ]]
}

current_file() {
    mpc current -f "%file%" 2>/dev/null
}

current_track_label() {
    mpc current -f "[%artist% - ]%title%|%file%"
}

# ---------------------------------------------------------------------------
# Station lookup — the only functions that know about stations.json.
# ---------------------------------------------------------------------------

station_name_for() {
    local file="$1"
    jq -r --arg url "$file" \
        '[.[] | select(.url == $url)][0].name // empty' \
        "$STATIONS_FILE"
}

is_station_file() {
    [[ -n "$(station_name_for "$1")" ]]
}

# ---------------------------------------------------------------------------
# Mode resolution — single source of truth every widget reads from.
# ---------------------------------------------------------------------------

current_mode() {
    if ! mpd_available; then
        echo "off"
    elif is_station_file "$(current_file)"; then
        echo "radio"
    elif [[ -n "$(current_file)" ]]; then
        echo "music"
    else
        echo "off"
    fi
}

playback_class() {
    mpd_playing && echo "playing" || echo "paused"
}

# ---------------------------------------------------------------------------
# JSON output — shared shape for every waybar custom-module.
# ---------------------------------------------------------------------------

emit() {
    local text="$1" class="$2"
    jq -nc --arg text "$text" --arg class "$class" '{text: $text, class: $class}'
}

emit_hidden() {
    emit "" "$1"
}

# ---------------------------------------------------------------------------
# Widgets — one function per waybar module, each reads current_mode() fresh.
# ---------------------------------------------------------------------------

widget_title() {
    local mode; mode="$(current_mode)"

    case "$mode" in
        off)
            emit "$(mpd_available && echo "No media" || echo "MPD dead")" "off"
            ;;
        radio)
            local name; name="$(station_name_for "$(current_file)")"
            emit "Station - ${name:-Unknown}" "$(playback_class)"
            ;;
        music)
            local icon; icon=$(mpd_playing && echo "$ICON_PLAYING" || echo "$ICON_PAUSED")
            emit "$icon $(current_track_label)" "$(playback_class)"
            ;;
    esac
}

# Brackets stand alone — visible whenever anything is loaded, regardless
# of which inner buttons happen to be shown.
widget_bracket() {
    local glyph="$1" mode; mode="$(current_mode)"
    [[ "$mode" == "off" ]] && { emit_hidden "off"; return; }
    emit "$glyph" "$mode"
}

# Track navigation only makes sense for a local playlist.
widget_track_nav() {
    local label="$1" mode; mode="$(current_mode)"
    [[ "$mode" == "music" ]] || { emit_hidden "$mode"; return; }
    emit "$label" "$mode"
}

widget_toggle() {
    local mode; mode="$(current_mode)"
    [[ "$mode" == "off" ]] && { emit_hidden "off"; return; }
    emit "$(mpd_playing && echo "pause" || echo "play")" "$mode"
}

widget_kill() {
    local mode; mode="$(current_mode)"
    [[ "$mode" == "off" ]] && { emit_hidden "off"; return; }
    emit "kill" "$mode"
}

# ---------------------------------------------------------------------------
# Actions — the only functions allowed to mutate MPD state.
# ---------------------------------------------------------------------------

action_prev()   { mpc prev >/dev/null; }
action_next()   { mpc next >/dev/null; }
action_toggle() { mpc toggle >/dev/null; }

action_kill() {
    mpc stop >/dev/null
    mpc clear >/dev/null
}

action_open_player() {
    process_is_running "ncmpcpp" || eval "$PLAYER_COMMAND"
}

# ---------------------------------------------------------------------------
# CLI dispatch
# ---------------------------------------------------------------------------

main() {
    case "${1:-}" in
        -j|--title-json)      widget_title ;;
        --bracket-open-json)  widget_bracket "[" ;;
        --bracket-close-json) widget_bracket "]" ;;
        --prev-json)          widget_track_nav "prev" ;;
        --next-json)          widget_track_nav "next" ;;
        --status-json)        widget_toggle ;;
        --kill-json)          widget_kill ;;
        -p|--prev)            action_prev ;;
        -n|--next)             action_next ;;
        -t|--toggle)           action_toggle ;;
        -k|--kill)              action_kill ;;
        -o|--open)               action_open_player ;;
        *)
            log_error "Unknown command: ${1:-}"
            exit 1
            ;;
    esac
}

main "$@"
