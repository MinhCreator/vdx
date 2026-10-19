#!/usr/bin/env bash
#
# brightness.sh — backlight and night light backend for modules/brightness.
#
#   --get                      {brightness}   backlight, %; none: {ok: false, error: "no backlight"}
#   --set N                    {brightness}   set the backlight to N %
#   --step ±N                  {brightness}   change the backlight by N %
#   --apply TEMPERATURE GAMMA  {ok, error}    TEMPERATURE in K or "off", GAMMA in %
#
# hyprsunset runs as a daemon (started in identity mode on first use) and is
# driven over its IPC, so night light and dimming change without a restart.

set -u

# the backlight class only: with no backlight brightnessctl would take an LED
emit() {
    local line
    line=$(brightnessctl -m -c backlight 2>/dev/null | head -1)
    [[ -n "$line" ]] || { echo '{"ok":false,"error":"no backlight"}'; return; }
    awk -F, '{ sub("%", "", $4); printf "{\"brightness\":%d}\n", $4 }' <<<"$line"
}

daemon() {
    pgrep -x hyprsunset >/dev/null && return
    setsid -f hyprsunset -i >/dev/null 2>&1
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        hyprctl hyprsunset gamma >/dev/null 2>&1 && return
        sleep 0.1
    done
}

cmd_apply() {
    daemon
    if [[ "$1" == off ]]; then
        hyprctl hyprsunset identity
    else
        hyprctl hyprsunset temperature "$1"
    fi >/dev/null 2>&1
    if hyprctl hyprsunset gamma "$2" >/dev/null 2>&1; then
        echo '{"ok":true}'
    else
        echo '{"ok":false,"error":"hyprsunset is not reachable"}'
    fi
}

case "${1:-}" in
    --get)   emit ;;
    --set)   brightnessctl -q -n1 -c backlight set "${2:-0}%"; emit ;;
    --step)
        case "${2:-0}" in
            -*) brightnessctl -q -n1 -c backlight set "${2#-}%-" ;;
            *)  brightnessctl -q -n1 -c backlight set "+${2#+}%" ;;
        esac
        emit
        ;;
    --apply) cmd_apply "${2:-off}" "${3:-100}" ;;
    *)       echo '{"ok":false,"error":"unknown command"}' ;;
esac
