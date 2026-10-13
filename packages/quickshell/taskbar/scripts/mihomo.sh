#!/usr/bin/env bash
#
# mihomo.sh — backend for the Quickshell mihomo widget.
#
# Thin layer between the widget and the two things it needs to talk to:
#   * the subscription manager (manager.py under packages/scripts/vpn/),
#     which owns subscriptions.json, downloads every subscription and renders
#     config.yaml from config.template.yaml. It is the ONLY writer of
#     config.yaml.
#   * mihomo's REST API — status, node switching, health checks, reload.
#
# config.yaml is a rendered artefact. To add, remove or change a provider,
# edit subscriptions.json (or press SAVE in the widget, which appends to that
# file) and let the renderer rebuild proxy-providers + the group `use:` list.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

API="${MIHOMO_API:-http://127.0.0.1:9090}"
SERVICE="${MIHOMO_SERVICE:-mihomo.service}"
GROUP="${MIHOMO_GROUP:-Proxies}"
TIMEOUT="${MIHOMO_TIMEOUT:-3}"
MIHOMO_DIR="${MIHOMO_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mihomo}"

# The subscription manager. A Python script under the dotfiles; run with `uv`
# so it resolves its inline `requests` dependency on the fly. Not a shell
# script, not a symlink, not an alias — just a file path.
VPN_MANAGER="${VPN_MANAGER:-$HOME/.dotfiles/packages/scripts/vpn/manager.py}"
SUBS_JSON="${SUBS_JSON:-$MIHOMO_DIR/subscriptions.json}"

# Single entry point. Everything that needs the manager goes through here.
vpn() {
    uv run --quiet "$VPN_MANAGER" "$@"
}

vpn_available() {
    [[ -f "$VPN_MANAGER" ]] && command -v uv >/dev/null 2>&1
}

# curl that never trips `set -e` (the controller may legitimately be down).
api() { curl -sf --max-time "$TIMEOUT" "$API$1" 2>/dev/null || true; }

# The policy group the rules actually use. Prefer $GROUP; otherwise fall back to
# the first non-GLOBAL Selector / URLTest / Fallback / LoadBalance group.
group_name() {
    local g
    g="$(api "/proxies/$GROUP" | jq -r '.type // ""' 2>/dev/null || true)"
    if [[ -n "$g" ]]; then
        printf '%s\n' "$GROUP"
        return 0
    fi
    api /proxies | jq -r '
        .proxies | to_entries[]
        | select(.value.type | test("^(Selector|URLTest|Fallback|LoadBalance)$"))
        | select(.key != "GLOBAL")
        | .key
    ' 2>/dev/null | head -n1 || true
}

cmd_status() {
    local svc="off" mode="rule" group node provider delay="0" proxies
    if service_is_active "$SERVICE"; then svc="on"; fi
    mode="$(api /configs | jq -r '.mode // "rule"' 2>/dev/null || true)"
    group="$(group_name)"
    if [[ -n "$group" ]]; then
        node="$(api "/proxies/$group" | jq -r '.now // ""' 2>/dev/null || true)"
    fi
    # /proxies carries both the provider-name and the node's ping history;
    # reading it once avoids URL-encoding the (unicode) node name.
    proxies="$(api /proxies)"
    if [[ -n "$node" ]]; then
        provider="$(printf '%s' "$proxies" | jq -r --arg n "$node" '.proxies[$n]["provider-name"] // ""' 2>/dev/null || true)"
        delay="$(printf '%s' "$proxies" | jq -r --arg n "$node" '((.proxies[$n].history // []) | last | .delay) // 0' 2>/dev/null || true)"
    fi
    [[ -z "$delay" || ! "$delay" =~ ^[0-9]+$ ]] && delay=0
    jq -nc --arg s "$svc" --arg m "${mode:-rule}" --arg g "${group:-}" \
           --arg n "${node:-}" --arg p "${provider:-}" --argjson d "$delay" \
        '{service:$s, mode:$m, group:$g, node:$n, provider:$p, delay:$d}'
}

cmd_providers() {
    api /providers/proxies | jq -c '
        [ .providers | to_entries[]
          | select(.key != "default")
          | select(.value.vehicleType != "Compatible")
          | select((.value.proxies // []) | length > 0)
          | { name: .key, nodes: ((.value.proxies // []) | length) } ]
    ' 2>/dev/null || true
}

cmd_nodes() {
    local provider="${1:-}"
    [[ -z "$provider" ]] && { printf '[]\n'; return 0; }
    api "/providers/proxies/$provider" | jq -c '
        [ (.proxies // [])[]
          | { name: .name,
              alive: (.alive // false),
              delay: (((.history // []) | last | .delay) // 0) } ]
    ' 2>/dev/null || true
}

cmd_select() {
    local node="${1:-}" group
    [[ -z "$node" ]] && return 0
    group="$(group_name)"
    [[ -z "$group" ]] && return 0
    curl -sf --max-time "$TIMEOUT" -X PUT "$API/proxies/$group" \
        -H 'Content-Type: application/json' \
        -d "$(jq -nc --arg n "$node" '{name:$n}')" >/dev/null 2>&1 || true
}

cmd_ping() {
    local provider="${1:-}" code alive
    if [[ -z "$provider" ]]; then
        printf '{"ok":false,"error":"no provider"}\n'
        return 1
    fi
    # Blocking health-check; the provider detail is re-read afterwards. The
    # endpoint answers 204 with no body, so read the status code explicitly.
    code="$(curl -s -o /dev/null -w '%{http_code}' \
        --max-time "${MIHOMO_PING_TIMEOUT:-20}" \
        "$API/providers/proxies/$provider/healthcheck" 2>/dev/null || true)"
    if [[ "$code" != "204" && "$code" != "200" ]]; then
        printf '{"ok":false,"error":"healthcheck HTTP %s"}\n' "${code:-000}"
        return 1
    fi
    alive="$(api "/providers/proxies/$provider" \
        | jq -r '[ (.proxies // [])[] | select(.alive == true) ] | length' 2>/dev/null || true)"
    if [[ "${alive:-0}" -gt 0 ]]; then
        printf '{"ok":true,"alive":%s}\n' "$alive"
    else
        printf '{"ok":false,"error":"no alive servers"}\n'
        return 1
    fi
}

cmd_traffic() {
    # Stream the controller's per-second traffic. `exec` so the Process can be
    # stopped cleanly (no bash left waiting on curl -> no orphan).
    exec curl -sN "$API/traffic"
}

# Timestamped line in the mihomo directory — only written on a failed update,
# so the folder keeps the most recent failure for diagnosis.
update_log() {
    mkdir -p "$MIHOMO_DIR" 2>/dev/null || true
    printf '[%s] %s\n' "$(date '+%F %T')" "$*" \
        >> "$MIHOMO_DIR/update.log" 2>/dev/null || true
}

# Best-effort config reload. If the controller is down the render still stands
# and takes effect the next time mihomo starts.
reload_config() {
    local cfg="$1"
    curl -sf --max-time "$TIMEOUT" "$API/version" >/dev/null 2>&1 || return 0
    curl -s -o /dev/null --max-time "${MIHOMO_RELOAD_TIMEOUT:-10}" \
        -X PUT "$API/configs?force=true" \
        -H 'Content-Type: application/json' \
        -d "$(jq -nc --arg p "$cfg" '{path:$p}')" 2>/dev/null || true
}

# ---- update ------------------------------------------------------------------
# Re-download every subscription through the manager, then ask mihomo to
# reload config.yaml so it picks up the freshly written provider files and the
# re-rendered proxy-providers block. The manager is the only thing that talks
# to subscription URLs — mihomo uses `type: file` providers and never fetches.
cmd_update() {
    local out rc=0

    if ! vpn_available; then
        update_log "manager not found at $VPN_MANAGER or uv missing"
        printf '{"ok":false,"error":"vpn manager not found"}\n'
        return 1
    fi

    out="$(vpn --update 2>&1)" || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        update_log "vpn --update failed: $out"
        printf '{"ok":false,"error":"vpn --update failed"}\n'
        return 1
    fi

    reload_config "$MIHOMO_DIR/config.yaml"
    printf '{"ok":true}\n'
}

# ---- add a provider ----------------------------------------------------------
# Only subscriptions.json is touched here. The renderer in manager.py rebuilds
# config.yaml on every `--update`, so there is exactly one writer of the
# runtime config and no chance of the two files drifting apart.
cmd_add_provider() {
    local name="${1:-}" url="${2:-}"
    local provider_path subs_tmp back_json out rc=0

    if [[ -z "$name" || -z "$url" ]]; then
        printf '{"ok":false,"error":"name and url required"}\n'; return 1
    fi
    if [[ ! "$name" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        printf '{"ok":false,"error":"invalid name"}\n'; return 1
    fi
    if [[ ! "$url" =~ ^https?:// ]]; then
        printf '{"ok":false,"error":"invalid url"}\n'; return 1
    fi
    if ! vpn_available; then
        printf '{"ok":false,"error":"vpn manager not found"}\n'; return 1
    fi
    if ! command -v jq >/dev/null 2>&1; then
        printf '{"ok":false,"error":"jq required"}\n'; return 1
    fi

    provider_path="$MIHOMO_DIR/providers/$name.yaml"

    if [[ ! -f "$SUBS_JSON" ]]; then
        printf '{"headers":{},"subscriptions":[]}\n' > "$SUBS_JSON"
    fi

    if jq -e --arg n "$name" '.subscriptions[] | select(.name == $n)' "$SUBS_JSON" \
         >/dev/null 2>&1; then
        printf '{"ok":false,"error":"provider already exists"}\n'; return 1
    fi

    subs_tmp="$(mktemp "${TMPDIR:-/tmp}/mihomo-subs.XXXXXX")" || {
        printf '{"ok":false,"error":"temp file"}\n'; return 1
    }
    if ! jq --arg n "$name" --arg u "$url" --arg p "$provider_path" '
        .subscriptions += [{ name: $n, url: $u, path: $p, decode: false }]
    ' "$SUBS_JSON" > "$subs_tmp"; then
        rm -f "$subs_tmp"
        printf '{"ok":false,"error":"could not update subscriptions.json"}\n'; return 1
    fi
    back_json="$(mktemp "${TMPDIR:-/tmp}/mihomo-subs-bak.XXXXXX")" || {
        rm -f "$subs_tmp"
        printf '{"ok":false,"error":"temp file"}\n'; return 1
    }
    cp -f "$SUBS_JSON" "$back_json"
    cat "$subs_tmp" > "$SUBS_JSON"
    rm -f "$subs_tmp"

    # The manager downloads the new subscription and re-renders config.yaml.
    # Roll subscriptions.json back on failure so a bad URL does not leave a
    # broken entry behind.
    out="$(vpn --update 2>&1)" || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        cp -f "$back_json" "$SUBS_JSON"
        rm -f "$back_json"
        update_log "add-provider '$name': vpn --update failed: $out"
        printf '{"ok":false,"error":"vpn --update failed"}\n'; return 1
    fi
    rm -f "$back_json"

    reload_config "$MIHOMO_DIR/config.yaml"
    printf '{"ok":true,"name":%s}\n' "$(jq -nc --arg n "$name" '$n')"
}

# ---- provider file / config path --------------------------------------------
# The renderer writes absolute paths into config.yaml (see manager.py), so the
# lookup is a straight read of `path:` out of the rendered file.
provider_file() {
    local provider="$1" rel
    rel="$(awk -v p="$provider" '
        $0 ~ "^  " p ":[[:space:]]*$" { inblk = 1; next }
        inblk && /^  [^ ]/ { inblk = 0 }
        inblk && /^[[:space:]]+path:[[:space:]]*/ {
            sub(/^[[:space:]]*path:[[:space:]]*/, "");
            gsub(/"/, "");
            print; exit
        }
    ' "$MIHOMO_DIR/config.yaml" 2>/dev/null || true)"
    if [[ -z "$rel" ]]; then
        rel="$MIHOMO_DIR/providers/$provider.yaml"
    fi
    if [[ "$rel" != /* ]]; then
        printf '%s\n' "$MIHOMO_DIR/${rel#./}"
    else
        printf '%s\n' "$rel"
    fi
}

cmd_config_path() {
    printf '%s\n' "$MIHOMO_DIR/config.yaml"
}

cmd_path() {
    local provider="${1:-}" file
    [[ -z "$provider" ]] && { printf '\n'; return 0; }
    file="$(provider_file "$provider")"
    if [[ -f "$file" ]]; then
        printf '%s\n' "$file"
    else
        printf '%s\n' "$MIHOMO_DIR/config.yaml"
    fi
}

main() {
    case "${1:-}" in
        --status)    cmd_status ;;
        --providers) cmd_providers ;;
        --nodes)     cmd_nodes "${2:-}" ;;
        --select)    cmd_select "${2:-}" ;;
        --ping)      cmd_ping "${2:-}" ;;
        --update)    cmd_update ;;
        --add-provider) cmd_add_provider "${2:-}" "${3:-}" ;;
        --traffic)   cmd_traffic ;;
        --config-path) cmd_config_path ;;
        --path)      cmd_path "${2:-}" ;;
        --toggle)    service_toggle "$SERVICE" ;;
        *)
            log_error "Unknown command: ${1:-}"
            exit 1
            ;;
    esac
}

main "$@"
