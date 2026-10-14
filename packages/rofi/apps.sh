#!/bin/bash
# rofi mode "apps": entries from menu.json
CONFIG="$HOME/.config/rofi/menu.json"

if [ ! -f "$CONFIG" ]; then
    notify-send "Rofi Menu" "File $CONFIG not found!"
    exit 1
fi

run_cmd() {
    ( setsid bash -c "$1" >/dev/null 2>&1 & )
}

show() {
    printf '\0use-hot-keys\x1ftrue\n'
    jq -r 'keys_unsorted[]' "$CONFIG"
}

run() {
    local cmd
    cmd=$(jq -r --arg k "$1" '.[$k]' "$CONFIG")
    if [ -n "$cmd" ] && [ "$cmd" != "null" ]; then
        run_cmd "$cmd"
    else
        notify-send "Rofi Menu" "Command '$1' not found"
        exit 1
    fi
}

case "${ROFI_RETV:-0}" in
    0) show ;;
    1) run "$1" ;;
    10) show ;;
    *) exit 0 ;;
esac
