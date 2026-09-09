#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

NIGHT_TEMP=5000
ICON_NIGHT="󰌵"
ICON_DAY="󰃠"
TOGGLE_DELAY=0.1

get_brightness() {
    local current max
    current=$(brightnessctl get 2>/dev/null || echo 0)
    max=$(brightnessctl max 2>/dev/null || echo 1)
    
    if [[ "$max" -le 0 ]]; then
        echo "0"
        return
    fi
    
    awk -v cur="$current" -v mx="$max" 'BEGIN { printf "%.0f", (cur / mx) * 100 }'
}

night_mode_active() {
    process_is_running "hyprsunset"
}

toggle_night_mode() {
    if night_mode_active; then
        pkill -x "hyprsunset"
    else
        hyprsunset --temperature "$NIGHT_TEMP" > /dev/null 2>&1 &
    fi
    sleep "$TOGGLE_DELAY"
}

main() {
    if [[ "${1:-}" == "--toggle" ]]; then
        toggle_night_mode
    fi

    local brightness icon class
    brightness=$(get_brightness)
    
    if night_mode_active; then
        icon="$ICON_NIGHT"
        class="on"
    else
        icon="$ICON_DAY"
        class="off"
    fi
    
    waybar_json "$icon  $brightness" "$class" "Brightness: $brightness%"
}

main "$@"

