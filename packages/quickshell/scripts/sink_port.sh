#!/usr/bin/env bash
#
# sink_port.sh — active-port probe for the bar's pulseaudio widget.
#
# waybar derives its `headphone` format-icon from the pulse backend's sink port
# name ("headphone"/"headset"/...). Pipewire's Quickshell service doesn't expose
# that port cleanly, so this mirrors the detection with a tiny pactl query.
#
# Prints "headphone" when the default sink's active port is a headphone jack,
# otherwise "other". Never fails (prints "other" on any error).

set -euo pipefail

default_sink="$(pactl get-default-sink 2>/dev/null || true)"
if [[ -z "$default_sink" ]]; then
    echo "other"
    exit 0
fi

active_port="$(pactl list sinks 2>/dev/null | awk -v want="$default_sink" '
    /^[[:space:]]*Name: / { name = $2; in_block = (name == want) }
    in_block && /Active Port:/ { print; exit }
' || true)"

if printf '%s' "$active_port" | grep -qi 'headphone'; then
    echo "headphone"
else
    echo "other"
fi
