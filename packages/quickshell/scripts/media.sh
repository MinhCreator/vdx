#!/usr/bin/env bash
#
# media.sh — the bar's media widget for MPD (local music + internet radio).
#
# MPD holds a single shared queue; this script never tracks state itself — it
# infers the mode by inspecting the queue and comparing it against
# stations.json. One fact, one place to check it.
#
#   --listen   long-running mode for the bar: emits one {"text","class"} line
#              per MPD event via `mpc idle` (re-polls every 2s while MPD is down)
#   --toggle   mpc toggle (wired to the module's on-click)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

readonly STATIONS_FILE="$HOME/.config/scripts/radio/stations.json"

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
# Mode resolution — single source of truth for the label.
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

# ---------------------------------------------------------------------------
# Title widget — the only output the bar renders.
# ---------------------------------------------------------------------------

widget_title() {
    local mode; mode="$(current_mode)"

    case "$mode" in
        off)
            emit_json "$(mpd_available && echo "No media" || echo "MPD dead")" "off"
            ;;
        radio)
            local name; name="$(station_name_for "$(current_file)")"
            emit_json "Station - ${name:-Unknown}" "$mode"
            ;;
        music)
            emit_json "$(current_track_label)" "$mode"
            ;;
    esac
}

# Continuous mode: emit one JSON line per MPD event so the bar doesn't re-run
# the script (and spawn mpc) every second.
widget_listen() {
    local prev=""
    while true; do
        local out
        out="$(widget_title)"
        if [[ -n "$out" && "$out" != "$prev" ]]; then
            printf '%s\n' "$out"
            prev="$out"
        fi
        if ! mpc idle player playlist >/dev/null 2>&1; then
            sleep 2
        fi
    done
}

# ---------------------------------------------------------------------------
# CLI dispatch
# ---------------------------------------------------------------------------

case "${1:-}" in
    --listen) widget_listen ;;
    --toggle) mpc toggle >/dev/null ;;
    *)
        log_error "Unknown command: ${1:-}"
        exit 1
        ;;
esac