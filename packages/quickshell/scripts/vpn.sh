#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

VPN_SERVICE="mihomo.service"
TOGGLE_DELAY=0.5

main() {
    if [[ "${1:-}" == "--toggle" ]]; then
        service_toggle "$VPN_SERVICE"
        sleep "$TOGGLE_DELAY"
    fi

    if service_is_active "$VPN_SERVICE"; then
        waybar_json "VPN" "connected"
    else
        waybar_json "VPN" "disconnected"
    fi
}

main "$@"

