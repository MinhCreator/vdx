#!/usr/bin/env bash
#
# network.sh — waybar/quickshell network widget (wifi / ethernet / none)
#
# Mirrors the waybar `network` module semantics for this config:
#   wifi      -> "  <essid>"     (U+F1EB, same glyph as modules/network.jsonc)
#   ethernet  -> ""               (format-ethernet is empty -> hidden)
#   otherwise -> "Disconnected"

set -euo pipefail

# Currently connected wifi ESSID (nmcli -t escapes values, so match the "yes:" prefix).
ssid="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        yes:*) printf '%s\n' "${line#yes:}"; break ;;
    esac
done)"

if [[ -n "$ssid" ]]; then
    printf '  %s\n' "$ssid"
    exit 0
fi

# No wifi — a connected wired link shows nothing (waybar format-ethernet is empty).
if nmcli -t -f TYPE,STATE device 2>/dev/null | grep -q '^ethernet:connected'; then
    exit 0
fi

printf 'Disconnected\n'
