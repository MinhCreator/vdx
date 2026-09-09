#!/bin/bash
CONFIG="$HOME/.config/rofi/scripts.json"

if [ ! -f "$CONFIG" ]; then
    notify-send "Rofi Menu" "File $CONFIG not found!"
    exit 1
fi

run_cmd() {
    ( setsid bash -c "$1" >/dev/null 2>&1 & )
}

is_folder() {
    [ "$(jq -r --arg n "$1" '.[$n].type // "toggle"' "$CONFIG")" = "folder" ]
}

child_cmd() {
    jq -r --arg p "$1" --arg c "$2" '.[$p].children[$c]' "$CONFIG"
}

toggle_state() {
    local check
    check=$(jq -r --arg n "$1" '.[$n].check' "$CONFIG")
    if [ "$check" = "null" ] || [ -z "$check" ]; then
        echo "off"
        return
    fi
    bash -c "$check" 2>/dev/null
}

show_top() {
    printf '\0use-hot-keys\x1ftrue\n'
    jq -r 'keys_unsorted[]' "$CONFIG" | while read -r name; do
        if is_folder "$name"; then
            printf '%s\0info\x1f%s\n' "$name" "$name"
        else
            if [ "$(toggle_state "$name")" = "on" ]; then
                printf '%s: ON\0info\x1f%s\n' "$name" "$name"
            else
                printf '%s: OFF\0info\x1f%s\n' "$name" "$name"
            fi
        fi
    done
}

show_folder() {
    local parent="$1"
    printf '\0prompt\x1f%s\n' "$parent"
    printf '\0use-hot-keys\x1ftrue\n'
    jq -r --arg p "$parent" '.[$p].children | keys_unsorted[]' "$CONFIG" | while read -r child; do
        printf '%s\0info\x1f%s\n' "$child" "$parent"
    done
}

run_child() {
    local parent="$1"
    local child="$2"
    local cmd
    cmd=$(child_cmd "$parent" "$child")
    if [ -n "$cmd" ] && [ "$cmd" != "null" ]; then
        run_cmd "$cmd"
    fi
}

toggle() {
    local name="$1"
    local cmd
    if [ "$(toggle_state "$name")" = "on" ]; then
        cmd=$(jq -r --arg n "$name" '.[$n].off' "$CONFIG")
    else
        cmd=$(jq -r --arg n "$name" '.[$n].on' "$CONFIG")
    fi
    if [ -n "$cmd" ] && [ "$cmd" != "null" ]; then
        run_cmd "$cmd"
    fi
}

case "${ROFI_RETV:-0}" in
    0)
        show_top
        ;;
    1)
        parent="${ROFI_INFO:-}"
        if is_folder "$parent"; then
            if [ "$1" = "$parent" ]; then
                show_folder "$parent"
            else
                run_child "$parent" "$1"
            fi
        elif [ -n "$parent" ]; then
            toggle "$parent"
        else
            show_top
        fi
        ;;
    10) show_top ;;
    *) exit 0 ;;
esac
