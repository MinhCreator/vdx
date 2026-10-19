#!/usr/bin/env bash
# supervise.sh — runs the shell (`qs -c shell`) and starts it again when its
# process ends by a crash. Quickshell restarts most crashes in place itself
# (same pid, a crash report window); this covers the rest: the OOM killer's
# KILL, a crash it gives up on. Not a JSON backend: Hyprland's autostart and
# the shell's Restart start it, in the foreground of their own process.
#   supervise.sh     until qs ends on purpose
# On purpose: exit 0 (a second instance too: `-n` exits 0 at once) or a kill
# by HUP / INT / TERM (Restart, `qs kill`, logout). Anything else is a crash
# (SEGV, ABRT, KILL from the OOM killer, an error code): mako draws toasts
# again (its island mode off: no island is left), and qs starts after a
# second; the 5th crash within a minute stops it, with a critical toast.
set -u

limit=5      # crashes ...
window=60    # ... within this many seconds stop it
crashes=()

while true; do
  qs -n -c shell
  code=$?
  case $code in 0 | 129 | 130 | 143) exit 0 ;; esac
  makoctl mode -r island >/dev/null 2>&1
  now=$(date +%s)
  recent=()
  for t in "${crashes[@]}"; do (( now - t < window )) && recent+=("$t"); done
  crashes=("${recent[@]}" "$now")
  if (( ${#crashes[@]} >= limit )); then
    notify-send -u critical -a Shell "The shell keeps crashing" \
      "Stopped after $limit crashes in a minute (last exit $code) · qs log -c shell"
    exit 1
  fi
  sleep 1
done
