#!/usr/bin/env bash
set -euo pipefail

log_error() {
    echo "[ERROR] $*" >&2
}

log_info() {
    echo "[INFO] $*" >&2
}

service_is_active() {
    local service="$1"
    systemctl --user is-active --quiet "$service"
}

service_toggle() {
    local service="$1"
    if service_is_active "$service"; then
        systemctl --user stop "$service"
    else
        systemctl --user start "$service"
    fi
}

process_is_running() {
    local name="$1"
    pgrep -x "$name" > /dev/null
}

waybar_json() {
    local text="$1"
    local class="${2:-}"
    local tooltip="${3:-}"
    
    if [[ -n "$tooltip" ]]; then
        printf '{"text":"%s","class":"%s","tooltip":"%s"}\n' "$text" "$class" "$tooltip"
    elif [[ -n "$class" ]]; then
        printf '{"text":"%s","class":"%s"}\n' "$text" "$class"
    else
        printf '{"text":"%s"}\n' "$text"
    fi
}
