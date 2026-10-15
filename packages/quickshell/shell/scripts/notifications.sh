#!/usr/bin/env bash
#
# notifications.sh — mako backend for plugins/notifications.
#
#   --list    [{id, app, summary, body, urgency}]  shown + history, newest first
#
# New notifications are detected by the service itself (dbus-monitor on the
# Notify method); this script only reads what mako holds.

case "${1:-}" in
    --list)
        { makoctl list -j 2>/dev/null || echo '[]'; makoctl history -j 2>/dev/null || echo '[]'; } |
        jq -cs 'add | map({id, app: (.app_name // ""), summary: (.summary // ""),
                           body: (.body // ""), urgency: (.urgency // 1)})
                    | unique_by(.id) | sort_by(-.id)'
        ;;
    *) jq -cn --arg c "${1:-}" '{ok:false, error:("unknown command: " + $c)}' ;;
esac
