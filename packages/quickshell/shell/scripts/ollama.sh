#!/usr/bin/env bash
#
# ollama.sh — local Ollama backend for plugins/claude (the AI plugin).
#
#   --status        {installed, running, version, models: [{name, size}],
#                    loaded: [{name, vram}]}       bytes
#   --start         run `ollama serve` as this user, detached   {ok | error}
#   --stop          stop this user's `ollama serve`            {ok | error}
#   --pull NAME     download a model (blocks until done)       {ok | error}
#   --unload NAME   drop a loaded model from memory            {ok | error}
#
# With the system ollama.service installed, start / stop go through systemctl
# (system/etc/polkit-1/rules.d/50-ollama.rules lets wheel do it without a
# password); otherwise the server runs as the user, logging to
# ~/.cache/ollama-serve.log.

API="${OLLAMA_HOST:-http://127.0.0.1:11434}"
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/ollama-serve.log"

ok()    { echo '{"ok":true}'; }
service() { systemctl list-unit-files ollama.service --no-legend 2>/dev/null | grep -q ollama; }
error() { jq -cn --arg e "$1" '{ok:false, error:$e}'; }
api()   { curl -s --max-time 3 "$API$1"; }

cmd_status() {
    if ! command -v ollama >/dev/null; then
        echo '{"installed":false,"running":false}'
        return
    fi
    local version
    version=$(api /api/version | jq -r '.version // empty' 2>/dev/null)
    if [[ -z "$version" ]]; then
        echo '{"installed":true,"running":false}'
        return
    fi
    jq -cn --arg version "$version" \
           --argjson tags "$(api /api/tags || echo '{}')" \
           --argjson ps "$(api /api/ps || echo '{}')" \
        '{installed: true, running: true, version: $version,
          models: [($tags.models // [])[] | {name, size}],
          loaded: [($ps.models // [])[] | {name, vram: (.size_vram // .size // 0)}]}'
}

cmd_start() {
    command -v ollama >/dev/null || { error "ollama is not installed"; return; }
    api /api/version >/dev/null && { ok; return; }
    if service; then
        systemctl start ollama 2>/dev/null || { error "systemctl start failed (install the polkit rule)"; return; }
    else
        mkdir -p "$(dirname "$LOG")"
        setsid -f ollama serve >>"$LOG" 2>&1
    fi
    for _ in $(seq 20); do
        api /api/version >/dev/null && { ok; return; }
        sleep 0.25
    done
    error "server did not start, see $LOG"
}

cmd_stop() {
    if service; then
        systemctl stop ollama 2>/dev/null && ok || error "systemctl stop failed (install the polkit rule)"
    else
        pkill -u "$USER" -x ollama && ok || error "ollama is not running"
    fi
}

cmd_pull() {
    [[ -z "$1" ]] && { error "no model"; return; }
    local out
    out=$(ollama pull "$1" 2>&1) && ok || error "$(tail -n1 <<<"$out")"
}

cmd_unload() {
    [[ -z "$1" ]] && { error "no model"; return; }
    curl -s --max-time 10 "$API/api/generate" -d "$(jq -cn --arg m "$1" '{model:$m, keep_alive:0}')" >/dev/null &&
        ok || error "could not unload"
}

case "${1:-}" in
    --status) cmd_status ;;
    --start)  cmd_start ;;
    --stop)   cmd_stop ;;
    --pull)   cmd_pull "${2:-}" ;;
    --unload) cmd_unload "${2:-}" ;;
    *)        error "unknown command: ${1:-}" ;;
esac
