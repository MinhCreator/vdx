#!/usr/bin/env bash
#
# codex.sh — Codex CLI backend for modules/ai (the AI module).
#
#   --usage      {ok, plan, at, limits: [{kind, percent, resets_at}] | error}
#                plan limits as Codex last saw them: the newest `token_count`
#                event of its session logs (~/.codex/sessions); `at` is that
#                event's time. No network and no token: the numbers are as old
#                as the last Codex answer. A window past its reset reads 0 %.
#                kind: session (the 5 h window), weekly_all (the week), else window_<minutes>

CODEX="${CODEX_HOME:-$HOME/.codex}"

error() { jq -cn --arg e "$1" '{ok:false, error:$e}'; }

cmd_usage() {
    local f line
    [[ -d "$CODEX/sessions" ]] || { error "no Codex sessions"; return; }
    # the newest logs first: the latest event is in one of them
    while IFS= read -r f; do
        line=$(grep '"rate_limits":{' "$f" | tail -1)
        [[ -n "$line" ]] && break
    done < <(find "$CODEX/sessions" -name '*.jsonl' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -5 | cut -d' ' -f2-)
    [[ -z "$line" ]] && { error "no limits yet — ask Codex something"; return; }

    jq -c --argjson now "$(date +%s)" '
        .payload.rate_limits as $r
        | def kind: if .window_minutes == 300 then "session"
                    elif .window_minutes == 10080 then "weekly_all"
                    else "window_\(.window_minutes)" end;
          {ok: true, plan: ($r.plan_type // ""), at: .timestamp,
           limits: [$r.primary, $r.secondary | select(. != null)
                    | {kind: kind,
                       percent: (if (.resets_at // 0) < $now then 0 else (.used_percent // 0 | round) end),
                       resets_at: ((.resets_at // $now) | todate)}]}' <<<"$line" 2>/dev/null ||
        error "unexpected log line"
}

case "${1:-}" in
    --usage) cmd_usage ;;
    *)       error "unknown command: ${1:-}" ;;
esac
