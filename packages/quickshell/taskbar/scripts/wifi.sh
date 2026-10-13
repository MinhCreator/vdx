#!/usr/bin/env bash
# wifi.sh — NetworkManager backend for plugins/wifi/WifiService.qml.
# Every command prints one JSON value; --traffic streams one object per second.
#
#   --status             {radio, state, ssid, ip, gateway}
#   --list               [{ssid, signal, secure, active, saved}]
#   --scan               {ok}                rescan and give NM time to collect results
#   --radio on|off       {ok}
#   --connect SSID       {ok, error}         password, if any, comes in $WIFI_PASS
#   --dns get            {ok, auto, servers}
#   --dns set [SERVERS]  {ok, error}         comma-separated; empty means DHCP
#   --ping               {ok, ping, loss}    gateway RTT (ms), packet loss (%)
#   --speedtest          {ok, down, up, ping, jitter, duration, ip, server}  Mbps / ms / s
#   --traffic            {up, down, upTotal, downTotal}  bytes

set -u
export LC_ALL=C

for bin in nmcli jq; do
  command -v "$bin" >/dev/null || { echo "{\"ok\":false,\"error\":\"$bin is required\"}"; exit 0; }
done

ok()    { echo '{"ok":true}'; }
error() { jq -cn --arg e "$1" '{ok:false, error:$e}'; }
num()   { echo "${1:-0}"; }

dev()       { nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}'; }
dev_field() { nmcli --escape no -g "$2" device show "$1" 2>/dev/null; }
radio_on()  { [ "$(nmcli radio wifi)" = enabled ]; }

active_uuid() {
  nmcli -t -f UUID,DEVICE connection show --active | awk -F: -v d="$1" '$2==d{print $1; exit}'
}

# "uuid<TAB>ssid" for every saved Wi-Fi profile.
saved_profiles() {
  local uuid type
  nmcli -t -f UUID,TYPE connection show | while IFS=: read -r uuid type; do
    [ "$type" = 802-11-wireless ] || continue
    printf '%s\t%s\n' "$uuid" "$(nmcli --escape no -g 802-11-wireless.ssid connection show uuid "$uuid")"
  done
}

uuid_for_ssid() { saved_profiles | awk -F'\t' -v s="$1" '$2==s{print $1; exit}'; }

cmd_status() {
  local d radio=off state=unavailable ssid="" ip="" gw=""
  d=$(dev)
  radio_on && radio=on
  if [ -n "$d" ]; then
    state=$(nmcli -t -f DEVICE,STATE device | awk -F: -v d="$d" '$1==d{print $2}')
    state=${state%% *}
    if [ "$state" = connected ]; then
      ssid=$(nmcli -t --escape no -f IN-USE,SSID device wifi list --rescan no 2>/dev/null | sed -n 's/^\*://p' | head -n1)
      [ -z "$ssid" ] && ssid=$(dev_field "$d" GENERAL.CONNECTION)
      ip=$(dev_field "$d" IP4.ADDRESS | head -n1)
      gw=$(dev_field "$d" IP4.GATEWAY | head -n1)
    fi
  fi
  jq -cn --arg radio "$radio" --arg state "$state" --arg ssid "$ssid" \
         --arg ip "${ip%%/*}" --arg gw "$gw" \
    '{radio:$radio, state:$state, ssid:$ssid, ip:$ip, gateway:$gw}'
}

# One entry per SSID: the access point in use, else the strongest one.
cmd_list() {
  local saved
  saved=$(saved_profiles | cut -f2 | jq -Rcs 'split("\n") | map(select(length > 0))')
  nmcli -t --escape no -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan no 2>/dev/null |
  jq -Rcs --argjson saved "$saved" '
    split("\n")
    | map(select(length > 0) | split(":") | {
        active: (.[0] == "*"),
        signal: ((.[1] | tonumber?) // 0),
        secure: (.[2] != "" and .[2] != "--"),
        ssid:   (.[3:] | join(":"))
      })
    | map(select(.ssid != ""))
    | group_by(.ssid)
    | map((map(select(.active)) + sort_by(-.signal))[0])
    | map(.ssid as $s | . + {saved: ($saved | any(. == $s))})
    | sort_by([(if .active then 0 else 1 end), -.signal])'
}

cmd_scan() {
  local d
  d=$(dev)
  { [ -n "$d" ] && radio_on; } || { error "wifi is off"; return; }
  nmcli device wifi rescan ifname "$d" >/dev/null 2>&1
  sleep 2
  ok
}

cmd_radio() {
  case "$1" in on|off) ;; *) error "expected on|off"; return ;; esac
  nmcli radio wifi "$1" >/dev/null 2>&1 && ok || error "could not switch radio"
}

cmd_connect() {
  local ssid=$1 pw=${WIFI_PASS:-} d uuid out
  d=$(dev)
  [ -z "$d" ] && { error "no wifi device"; return; }
  uuid=$(uuid_for_ssid "$ssid")

  if [ -n "$uuid" ]; then
    [ -n "$pw" ] && nmcli connection modify uuid "$uuid" wifi-sec.psk "$pw" >/dev/null 2>&1
    out=$(nmcli --wait 25 connection up uuid "$uuid" ifname "$d" 2>&1)
  else
    out=$(nmcli --wait 25 device wifi connect "$ssid" ${pw:+password "$pw"} ifname "$d" 2>&1)
  fi && { ok; return; }

  # A failed first connect still leaves a profile behind; drop it.
  if [ -z "$uuid" ]; then
    uuid=$(uuid_for_ssid "$ssid")
    [ -n "$uuid" ] && nmcli connection delete uuid "$uuid" >/dev/null 2>&1
  fi
  out=${out%%$'\n'*}
  error "${out#Error: }"
}

cmd_dns() {
  local d uuid=""
  d=$(dev)
  [ -n "$d" ] && uuid=$(active_uuid "$d")
  [ -z "$uuid" ] && { error "not connected"; return; }

  case "$1" in
    get)
      jq -cn --arg ignore "$(nmcli -g ipv4.ignore-auto-dns connection show uuid "$uuid")" \
             --arg servers "$(dev_field "$d" IP4.DNS | sed 's/ | /,/g')" \
        '{ok:true, auto:($ignore != "yes"), servers:$servers}'
      ;;
    set)
      if [ -n "$2" ]; then
        nmcli connection modify uuid "$uuid" ipv4.ignore-auto-dns yes ipv4.dns "$2"
      else
        nmcli connection modify uuid "$uuid" ipv4.ignore-auto-dns no ipv4.dns ""
      fi >/dev/null 2>&1 && nmcli device reapply "$d" >/dev/null 2>&1 && ok || error "could not apply DNS"
      ;;
    *) error "expected get|set" ;;
  esac
}

# "rtt min/avg/max/mdev = 1.2/2.3/3.4/0.5 ms"
rtt_avg()  { sed -nE 's|^rtt [^=]+= [0-9.]+/([0-9.]+)/.*|\1|p'; }
rtt_mdev() { sed -nE 's|^rtt [^=]+= [0-9.]+/[0-9.]+/[0-9.]+/([0-9.]+) ms.*|\1|p'; }

cmd_ping() {
  local d gw="" out
  d=$(dev)
  [ -n "$d" ] && gw=$(dev_field "$d" IP4.GATEWAY | head -n1)
  [ -z "$gw" ] && { error "no gateway"; return; }
  out=$(ping -c 3 -W 1 -q "$gw" 2>/dev/null)
  jq -cn --argjson ping "$(num "$(rtt_avg <<<"$out")")" \
         --argjson loss "$(num "$(sed -nE 's/.* ([0-9.]+)% packet loss.*/\1/p' <<<"$out")")" \
    '{ok:true, ping:$ping, loss:$loss}'
}

cmd_speedtest() {
  local host=speed.cloudflare.com ip pings t0 down up
  command -v curl >/dev/null || { error "curl is required"; return; }

  ip=$(curl -s --max-time 3 https://api.ipify.org)
  pings=$(ping -c 5 -W 1 -q 1.1.1.1 2>/dev/null)
  t0=$EPOCHREALTIME
  down=$(curl -s -o /dev/null -w '%{speed_download}' --connect-timeout 5 --max-time 20 \
         "https://$host/__down?bytes=10000000")
  up=$(head -c 5000000 /dev/zero | curl -s -o /dev/null -w '%{speed_upload}' \
       --connect-timeout 5 --max-time 20 --data-binary @- "https://$host/__up")

  [[ $down =~ ^[0-9.]+$ ]] || down=0
  [[ $up =~ ^[0-9.]+$ ]] || up=0
  [ "$down" = 0 ] && [ "$up" = 0 ] && { error "could not reach $host"; return; }

  jq -cn --argjson down "$down" --argjson up "$up" \
         --argjson ping "$(num "$(rtt_avg <<<"$pings")")" \
         --argjson jitter "$(num "$(rtt_mdev <<<"$pings")")" \
         --argjson duration "$(awk -v a="$t0" -v b="$EPOCHREALTIME" 'BEGIN{print b-a}')" \
         --arg ip "$ip" --arg server "$host" \
    '{ok:true, down:($down*8/1e6), up:($up*8/1e6), ping:$ping, jitter:$jitter,
      duration:$duration, ip:$ip, server:$server}'
}

cmd_traffic() {
  local d rx tx prx ptx
  d=$(dev)
  sample() { awk -v d="$d" '{sub(/:/, " ")} $1==d {print $2, $10}' /proc/net/dev; }
  read -r prx ptx < <(sample)
  prx=${prx:-0} ptx=${ptx:-0}
  while :; do
    read -r rx tx < <(sample)
    rx=${rx:-$prx} tx=${tx:-$ptx}
    echo "{\"up\":$((tx - ptx)),\"down\":$((rx - prx)),\"upTotal\":$tx,\"downTotal\":$rx}"
    prx=$rx ptx=$tx
    sleep 1
  done
}

case "${1:-}" in
  --status)    cmd_status ;;
  --list)      cmd_list ;;
  --scan)      cmd_scan ;;
  --radio)     cmd_radio "${2:-}" ;;
  --connect)   cmd_connect "${2:-}" ;;
  --dns)       cmd_dns "${2:-get}" "${3:-}" ;;
  --ping)      cmd_ping ;;
  --speedtest) cmd_speedtest ;;
  --traffic)   cmd_traffic ;;
  *)           error "unknown command: ${1:-}" ;;
esac
