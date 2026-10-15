#!/usr/bin/env bash
#
# claude.sh — Claude Code backend for modules/claude.
#
#   --usage      {ok, plan, limits: [{kind, percent, resets_at}] | error}
#                plan limits as in `/usage` (api.anthropic.com, OAuth token of
#                ~/.claude/.credentials.json; the token goes nowhere else)
#   --today      {messages, input, output, cache_read, cache_write}  from local logs
#   --sessions   [{name, cwd, status, version, started}]  running Claude Code sessions
#
# The token is never refreshed here (that is Claude Code's job): when it has
# expired, --usage reports it until Claude Code runs again.

CLAUDE="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
CREDS="$CLAUDE/.credentials.json"
API="https://api.anthropic.com/api/oauth/usage"

error() { jq -cn --arg e "$1" '{ok:false, error:$e}'; }

cmd_usage() {
    local token expires out
    [[ -r "$CREDS" ]] || { error "not logged in"; return; }
    token=$(jq -r '.claudeAiOauth.accessToken // empty' "$CREDS")
    expires=$(jq -r '.claudeAiOauth.expiresAt // 0' "$CREDS")
    [[ -z "$token" ]] && { error "not logged in"; return; }
    (( expires / 1000 < $(date +%s) )) && { error "token expired — open Claude Code"; return; }

    # Header via stdin: the token stays out of the process list.
    out=$(printf 'Authorization: Bearer %s\nanthropic-beta: oauth-2025-04-20\n' "$token" |
          curl -s --max-time 10 -H @- "$API") || { error "api.anthropic.com unreachable"; return; }
    jq -c --arg plan "$(jq -r '.claudeAiOauth.subscriptionType // ""' "$CREDS")" '
        if (.limits | type) == "array" then
          {ok: true, plan: $plan,
           limits: [.limits[] | {kind, percent: (.percent // 0), resets_at}]}
        else {ok: false, error: (.error.message // "unexpected answer")} end' <<<"$out" 2>/dev/null ||
        error "unexpected answer"
}

cmd_today() {
    local since
    since=$(date -d "today 00:00" -u +%FT%T)
    find "$CLAUDE/projects" -name '*.jsonl' -newermt "$(date +%F)" -print0 2>/dev/null |
    xargs -0 -r cat |
    jq -c --arg t "$since" 'select(.type == "assistant" and .message.usage and (.timestamp // "") >= $t)
                            | {k: (.message.id + (.requestId // "")), u: .message.usage}' |
    jq -sc 'unique_by(.k) | {messages: length,
             input: (map(.u.input_tokens // 0) | add // 0),
             output: (map(.u.output_tokens // 0) | add // 0),
             cache_read: (map(.u.cache_read_input_tokens // 0) | add // 0),
             cache_write: (map(.u.cache_creation_input_tokens // 0) | add // 0)}'
}

# Session files of exited processes linger; keep the ones whose pid is alive.
cmd_sessions() {
    local f out=()
    for f in "$CLAUDE"/sessions/*.json; do
        [[ -f "$f" ]] || continue
        kill -0 "$(jq -r '.pid' "$f")" 2>/dev/null && out+=("$f")
    done
    if (( ${#out[@]} == 0 )); then echo '[]'; return; fi
    jq -sc 'map({name: (.name // ""), cwd: (.cwd // ""), status: (.status // ""),
                 version: (.version // ""), started: (.startedAt // 0)})
            | sort_by(-.started)' "${out[@]}"
}

case "${1:-}" in
    --usage)    cmd_usage ;;
    --today)    cmd_today ;;
    --sessions) cmd_sessions ;;
    *)          error "unknown command: ${1:-}" ;;
esac
