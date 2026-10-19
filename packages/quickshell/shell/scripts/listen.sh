# listen.sh — sourced by the backends' --listen (wifi.sh, bluetooth.sh), not run.
#   listen_to CMD…   one {"ok":true} line per line CMD prints, until the shell
#                    that started us is gone, CMD ends or our stdout closes;
#                    CMD is killed on the way out (it would outlive us otherwise)
# Needs ok() from the backend.
# shellcheck shell=bash

listen_to() {
  local parent=$PPID code
  trap '' PIPE                                  # a closed stdout fails the write instead
  exec 3< <(exec stdbuf -oL "$@" 2>/dev/null)
  listen_mon=$!                                 # global: the EXIT trap runs after we return
  trap 'kill "$listen_mon" 2>/dev/null' EXIT
  while kill -0 "$parent" 2>/dev/null; do
    if read -r -t 2 -u 3 _; then
      ok || break
    else
      code=$?
      (( code > 128 )) || break                 # > 128: the timeout; else CMD ended
    fi
  done
}
