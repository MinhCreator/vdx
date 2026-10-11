#!/usr/bin/env bash
#
# mihomo.sh — backend for the Quickshell mihomo widget.
#
# The single place that talks to mihomo's external controller (REST). It only
# prints JSON for MihomoService.qml; mihomo itself stays the source of truth
# (no state is kept here), the same way the other quickshell scripts work.
#
# Read-only:
#   --status             {"service","mode","group","node","provider","delay"}
#                        (delay = last measured ping of the active node, ms)
#   --providers          [{"name","nodes"}]
#   --nodes <provider>   [{"name","alive","delay"}]   (delay = last measured, ms)
#   --traffic            stream: {"up","down","upTotal","downTotal"} once a second
# Actions:
#   --select <node>      make <node> the active server of the policy group
#   --ping <provider>    health-check every node of <provider>
#                        prints {"ok":true,"alive":N} or {"ok":false,"error":…}
#   --update             re-download every proxy-provider, then verify
#   --toggle             start/stop mihomo.service
#   --update prints {"ok":true} or {"ok":false,"error":…}; on failure it also
#   appends a line to $MIHOMO_DIR/update.log.
# Paths (for the popup's "open config" buttons):
#   --config-path        print the path of mihomo's config.yaml
#   --path <provider>    print the provider's own file (config.yaml as fallback)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=_common.sh
source "$SCRIPT_DIR/_common.sh"

API="${MIHOMO_API:-http://127.0.0.1:9090}"
SERVICE="${MIHOMO_SERVICE:-mihomo.service}"
GROUP="${MIHOMO_GROUP:-Proxies}"
TIMEOUT="${MIHOMO_TIMEOUT:-3}"
MIHOMO_DIR="${MIHOMO_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/mihomo}"

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
    # /proxies carries both provider-name and the node's ping history; reading
    # it once avoids URL-encoding the (unicode) node name.
    proxies="$(api /proxies)"
    if [[ -n "$node" ]]; then
        provider="$(printf '%s' "$proxies" | jq -r --arg n "$node" '.proxies[$n]["provider-name"] // ""' 2>/dev/null || true)"
        delay="$(printf '%s' "$proxies" | jq -r --arg n "$node" '((.proxies[$n].history // []) | last | .delay) // 0' 2>/dev/null || true)"
    fi
    # the active node's last measured ping (0 / empty -> no data yet)
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
# so the folder keeps the most recent failure for diagnosis. A failed write
# must never abort the update itself, hence the `|| true`s.
update_log() {
    mkdir -p "$MIHOMO_DIR" 2>/dev/null || true
    printf '[%s] %s\n' "$(date '+%F %T')" "$*" \
        >> "$MIHOMO_DIR/update.log" 2>/dev/null || true
}

# Re-download every proxy-provider from its subscription URL, then confirm the
# list actually refreshed (mihomo bumps updatedAt once the download is done).
cmd_update() {
    local rc=0 names name before after code i

    if ! curl -sf --max-time "$TIMEOUT" "$API/version" >/dev/null 2>&1; then
        update_log "mihomo controller unreachable at $API"
        printf '{"ok":false,"error":"controller unreachable"}\n'
        return 1
    fi

    names="$(api /providers/proxies | jq -r '
        .providers | to_entries[]
        | select(.key != "default")
        | select(.value.vehicleType != "Compatible")
        | .key
    ' 2>/dev/null || true)"

    if [[ -z "$names" ]]; then
        printf '{"ok":true,"providers":0}\n'
        return 0
    fi

    while IFS= read -r name; do
        [[ -z "$name" ]] && continue
        before="$(api "/providers/proxies/$name" | jq -r '.updatedAt // ""' 2>/dev/null || true)"

        code="$(curl -s -o /dev/null -w '%{http_code}' \
            --max-time "${MIHOMO_UPDATE_TIMEOUT:-30}" \
            -X PUT "$API/providers/proxies/$name" 2>/dev/null || true)"
        if [[ "$code" != "204" && "$code" != "200" ]]; then
            rc=1
            update_log "provider '$name': update request returned HTTP ${code:-000}"
            continue
        fi

        # updatedAt moves only once the subscription was fetched successfully.
        after="$before"
        for i in $(seq 1 12); do
            after="$(api "/providers/proxies/$name" | jq -r '.updatedAt // ""' 2>/dev/null || true)"
            [[ -n "$after" && "$after" != "$before" ]] && break
            sleep 0.5
        done
        if [[ -z "$after" || "$after" == "$before" ]]; then
            rc=1
            update_log "provider '$name': subscription did not refresh (updatedAt unchanged)"
        fi
    done <<< "$names"

    if [[ "$rc" -ne 0 ]]; then
        printf '{"ok":false,"error":"see update.log"}\n'
        return 1
    fi
    printf '{"ok":true}\n'
}

# The provider's file: honour an explicit `path:` in its proxy-providers block
# (relative paths resolve against MIHOMO_DIR), else the default layout.
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
        rel="providers/$provider.yaml"
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
