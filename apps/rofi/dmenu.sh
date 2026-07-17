#!/bin/bash
CONFIG="$HOME/.config/rofi/menu.json"

if [ ! -f "$CONFIG" ]; then
    notify-send "Rofi Menu" "File $CONFIG not founded!"
    exit 1
fi

CHOICE=$(jq -r 'keys_unsorted[]' "$CONFIG" | rofi -dmenu -i -p "Run:")

if [ -z "$CHOICE" ]; then
    exit 0
fi

CMD=$(jq -r --arg k "$CHOICE" '.[$k]' "$CONFIG")

if [ -n "$CMD" ] && [ "$CMD" != "null" ]; then
    bash -c "$CMD" &
else
    notify-send "Rofi Menu" "Command '$CHOICE' not founded"
    exit 1
fi
