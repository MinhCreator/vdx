#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

# brightness.sh — the bar's brightness module (labels + actions).
#
# Always prints fresh JSON — {"text":"<icon>  <NN>","class":"on|off"} — after
# any action, so the widget reflects it immediately instead of waiting for its
# poll. The step direction carries the sign: `--step +5` brightens, `--step -5`
# dims.
#
#   (no arg)   read current brightness + night mode
#   --toggle   toggle hyprsunset and print the new state
#   --step ±N  brightnessctl set +N% / N%- and print the new state

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

apply_step() {
    local delta="${1:-}"
    [[ "$delta" =~ ^[+-]?[0-9]+$ ]] || return
    if [[ "$delta" == -* ]]; then
        brightnessctl set "${delta#-}%-" >/dev/null 2>&1 || true
    else
        brightnessctl set "+${delta#+}%" >/dev/null 2>&1 || true
    fi
}

main() {
    case "${1:-}" in
        --toggle) toggle_night_mode ;;
        --step)   apply_step "${2:-}" ;;
    esac

    local brightness icon class
    brightness="$(get_brightness)"

    if night_mode_active; then
        icon="$ICON_NIGHT"
        class="on"
    else
        icon="$ICON_DAY"
        class="off"
    fi

    emit_json "$icon  $brightness" "$class"
}

main "$@"