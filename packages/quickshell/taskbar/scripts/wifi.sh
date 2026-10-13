#!/usr/bin/env bash
# wifi.sh — data layer for the quickshell Wi-Fi module (WifiService.qml).
#
# Talks to NetworkManager through nmcli; stdout is always JSON so the QML side
# only parses (StdioCollector), except --traffic which streams one JSON object
# per line (SplitParser). Needs: nmcli, jq, curl; qrencode optional (--qr).
#
#   --status              {radio,device,state,ssid,signal,security,ip,gateway}
#   --list                [{ssid,signal,security,secure,active,saved,bssid,chan,freq,rate,aps}]
#   --ping                {ok,ping,loss}  gateway latency + packet loss (%)
#   --speedtest           {ok,down,up}    bytes/sec via Cloudflare
#   --qr SSID             {ok,data,ssid,password}  base64 PNG + plaintext for the popup
#   --dns get             {mode,dns}
#   --dns set MODE [DNS]  {ok,error}      MODE in dhcp|cloudflare|google|custom
#   --scan                rescan, wait a moment -> {ok}
#   --radio on|off        {ok}
#   --connect SSID        {ok,error}; password (if any) comes in $WIFI_PASS
#   --disconnect          {ok,error}
#   --forget SSID         {ok,error}  (deletes every saved profile of that SSID)
#   --traffic             {up,down,upTotal,downTotal} every second

set -u
export LC_ALL=C   # stable nmcli output ("--" for open networks, "yes"/"no")

if ! command -v nmcli >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  echo '{"ok":false,"error":"nmcli and jq are required"}'
  exit 0
fi

dev() {
  nmcli -t --escape no -f DEVICE,TYPE device | awk -F: '$2=="wifi"{print $1; exit}'
}

radio_on() { [ "$(nmcli radio wifi)" = enabled ]; }

# ---- saved profiles ---------------------------------------------------------
saved_json() {
  local uuid type auto active name ssid
  nmcli -t --escape no -f UUID,TYPE,AUTOCONNECT,ACTIVE,NAME connection show |
  while IFS=: read -r uuid type auto active name; do
    case "$type" in 802-11-wireless|wifi) ;; *) continue ;; esac
    ssid=$(nmcli --escape no -g 802-11-wireless.ssid connection show uuid "$uuid" 2>/dev/null)
    jq -cn --arg uuid "$uuid" --arg name "$name" --arg ssid "$ssid" \
           --arg auto "$auto" --arg active "$active" \
      '{uuid:$uuid, name:$name, ssid:(if $ssid == "" then $name else $ssid end),
        autoconnect:($auto == "yes"), active:($active == "yes")}'
  done | jq -cs .
}

uuids_for_ssid() {
  saved_json | jq -r --arg s "$1" '.[] | select(.ssid == $s) | .uuid'
}

# ---- visible networks -------------------------------------------------------
scan_json() {
  local saved
  saved=$(saved_json)
  nmcli -t --escape no -f IN-USE,SIGNAL,SECURITY,CHAN,FREQ,RATE,BSSID,SSID \
        device wifi list --rescan no 2>/dev/null |
  jq -R -s --argjson saved "$saved" '
    ($saved | map(.ssid)) as $known
    | split("\n")
    | map(select(length > 0) | split(":") | {
        active:   (.[0] == "*"),
        signal:   ((.[1] | tonumber?) // 0),
        security: (if .[2] == "--" then "" else .[2] end),
        chan: .[3], freq: .[4], rate: .[5],
        bssid: (.[6:12] | join(":")),
        ssid:  (.[12:] | join(":"))
      })
    | map(select(.ssid != ""))
    | group_by(.ssid)
    | map(. as $g
        | (($g | map(select(.active)) | first) // ($g | sort_by(-.signal) | first))
          + {aps: ($g | length)})
    | map(. as $n | $n + {secure: ($n.security != ""),
                          saved: ($known | any(. == $n.ssid))})
    | sort_by([(if .active then 0 else 1 end), -.signal])'
}

# ---- commands ---------------------------------------------------------------
cmd_status() {
  local d radio=off state=unavailable line ssid="" sig=0 sec="" ip="" gw=""
  d=$(dev)
  radio_on && radio=on
  if [ -n "$d" ]; then
    state=$(nmcli -t -f DEVICE,STATE device | awk -F: -v d="$d" '$1==d{print $2}')
    case "$state" in
      connected*)  state=connected ;;
      connecting*) state=connecting ;;
    esac
    if [ "$state" = connected ]; then
      line=$(nmcli -t --escape no -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan no 2>/dev/null |
             grep -m1 '^\*:')
      IFS=: read -r _ sig sec ssid <<<"$line"
      [ "$sec" = "--" ] && sec=""
      [ -z "$ssid" ] && ssid=$(nmcli --escape no -g GENERAL.CONNECTION device show "$d")
      ip=$(nmcli --escape no -g IP4.ADDRESS device show "$d" 2>/dev/null | head -n1)
      ip=${ip%%/*}
      gw=$(nmcli --escape no -g IP4.GATEWAY device show "$d" 2>/dev/null | head -n1)
    fi
  fi
  jq -cn --arg radio "$radio" --arg device "$d" --arg state "$state" \
         --arg ssid "$ssid" --arg sig "${sig:-0}" --arg sec "$sec" \
         --arg ip "$ip" --arg gw "$gw" \
    '{radio:$radio, device:$device, state:$state, ssid:$ssid,
      signal:(($sig | tonumber?) // 0), security:$sec,
      ip:$ip, gateway:$gw}'
}

cmd_list() { scan_json; }

# ---- ping / packet loss -----------------------------------------------------
# Three ICMP probes to the default gateway; the info panel shows the RTT
# average (2nd number on the rtt line) and the loss percentage. grep -oE does
# not support lookahead, so the extraction is done with sed: match the whole
# phrase, capture the number.
cmd_ping() {
  local d gw out loss avg
  d=$(dev)
  [ -z "$d" ] && { echo '{"ok":false,"ping":0,"loss":0}'; return; }
  gw=$(nmcli --escape no -g IP4.GATEWAY device show "$d" 2>/dev/null | head -n1)
  [ -z "$gw" ] && { echo '{"ok":false,"ping":0,"loss":0}'; return; }
  out=$(ping -c 3 -W 1 -q "$gw" 2>/dev/null)
  # "3 packets transmitted, 3 received, 0% packet loss, time 2003ms"
  loss=$(printf '%s' "$out" | sed -nE 's/.* ([0-9]+)% packet loss.*/\1/p' | head -n1)
  # "rtt min/avg/max/mdev = 1.234/2.345/3.456/0.567 ms" — capture the AVG
  avg=$(printf '%s' "$out" | sed -nE 's|.*rtt [^=]+= [0-9.]+/([0-9.]+)/.*|\1|p' | head -n1)
  jq -cn --argjson ping "${avg:-0}" --argjson loss "${loss:-100}" \
    '{ok:true, ping:$ping, loss:$loss}'
}

# ---- speedtest --------------------------------------------------------------
# Cloudflare's public speed endpoints plus a few extra numbers for the popup:
# latency + jitter from 5 quick pings to 1.1.1.1, public IPv4 from ipify, and
# how long the whole test took. Download uses %{speed_download}, upload uses
# %{speed_upload}; both come back as bytes/sec (QML divides by 125000 for Mbps).
# The upload body is fed from /dev/zero via `head -c` — `dd … | curl
# --data-binary @-` silently drops to zero bytes on some dd/curl combinations,
# which is why the original test always reported 0.
cmd_speedtest() {
  local down up ping jitter duration ip server t0 t1 pingout
  if ! command -v curl >/dev/null 2>&1; then
    echo '{"ok":false,"error":"curl is not installed"}'; return
  fi

  server="speed.cloudflare.com"

  # Public IP — best effort, no failure if the service is unreachable
  ip=$(curl -s --max-time 3 https://api.ipify.org 2>/dev/null)
  [ -z "$ip" ] && ip="—"

  # Latency + jitter — 5 ICMP probes to the Cloudflare resolver
  pingout=$(ping -c 5 -W 1 -q 1.1.1.1 2>/dev/null)
  ping=$(printf '%s' "$pingout" | sed -nE 's|.*rtt [^=]+= [0-9.]+/([0-9.]+)/.*|\1|p' | head -n1)
  jitter=$(printf '%s' "$pingout" | sed -nE 's|.*rtt [^=]+= [0-9.]+/[0-9.]+/[0-9.]+/([0-9.]+)/.*|\1|p' | head -n1)
  [ -z "$ping" ] && ping=0
  [ -z "$jitter" ] && jitter=0

  t0=$(date +%s.%N)

  down=$(curl -s -o /dev/null -w '%{speed_download}' \
         --connect-timeout 5 --max-time 20 \
         "https://speed.cloudflare.com/__down?bytes=10000000" 2>/dev/null)

  up=$(head -c 5000000 /dev/zero 2>/dev/null | \
       curl -s -o /dev/null -w '%{speed_upload}' \
       --connect-timeout 5 --max-time 20 \
       -X POST --data-binary @- \
       "https://speed.cloudflare.com/__up" 2>/dev/null)

  t1=$(date +%s.%N)
  duration=$(awk -v a="$t0" -v b="$t1" 'BEGIN{printf "%.1f", b-a}')

  case "$down" in ''|*[!0-9.]*) down=0 ;; esac
  case "$up" in   ''|*[!0-9.]*) up=0   ;; esac

  if [ "$down" = "0" ] && [ "$up" = "0" ]; then
    echo '{"ok":false,"error":"could not reach speed.cloudflare.com"}'; return
  fi

  jq -cn --argjson d "$down" --argjson u "$up" \
         --argjson p "$ping" --argjson j "$jitter" \
         --argjson dur "$duration" \
         --arg ip "$ip" --arg srv "$server" \
    '{ok:true, down:$d, up:$u, ping:$p, jitter:$j,
      duration:$dur, ip:$ip, server:$srv}'
}

# ---- Wi-Fi QR ---------------------------------------------------------------
qr_escape() {
  printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/;/\\;/g' -e 's/,/\\,/g' \
                        -e 's/:/\\:/g' -e 's/"/\\"/g'
}

cmd_qr() {
  local ssid=${1:-} uuid="" psk="" payload data
  [ -z "$ssid" ] && { echo '{"ok":false,"error":"no ssid"}'; return; }
  if ! command -v qrencode >/dev/null 2>&1; then
    echo '{"ok":false,"error":"qrencode is not installed"}'; return
  fi
  uuid=$(uuids_for_ssid "$ssid" | head -n1)
  if [ -n "$uuid" ]; then
    psk=$(nmcli -s -g 802-11-wireless-security.psk connection show uuid "$uuid" 2>/dev/null)
  fi
  if [ -n "$psk" ]; then
    payload="WIFI:T:WPA;S:$(qr_escape "$ssid");P:$(qr_escape "$psk");;"
  else
    payload="WIFI:T:nopass;S:$(qr_escape "$ssid");;"
  fi
  data=$(qrencode -t PNG -o - -s 5 -m 4 "$payload" 2>/dev/null | base64 -w0)
  if [ -z "$data" ]; then
    echo '{"ok":false,"error":"qrencode failed"}'; return
  fi
  jq -cn --arg d "$data" --arg s "$ssid" --arg p "$psk" \
    '{ok:true, data:$d, ssid:$s, password:$p}'
}

# ---- DNS provider -----------------------------------------------------------
cmd_dns() {
  local action=$1 mode=$2 servers=$3
  local d name uuid ignore dns norm
  d=$(dev)
  [ -z "$d" ] && { echo '{"ok":false,"error":"no wifi device"}'; return; }
  name=$(nmcli --escape no -g GENERAL.CONNECTION device show "$d" 2>/dev/null)
  [ -z "$name" ] && { echo '{"ok":false,"error":"not connected"}'; return; }
  uuid=$(nmcli -t -f UUID,NAME connection show | awk -F: -v n="$name" '$2==n{print $1; exit}')
  [ -z "$uuid" ] && { echo '{"ok":false,"error":"profile not found"}'; return; }

  case "$action" in
    get)
      ignore=$(nmcli -g ipv4.ignore-auto-dns connection show uuid "$uuid" 2>/dev/null)
      dns=$(nmcli --escape no -g ipv4.dns connection show uuid "$uuid" 2>/dev/null)
      if [ "$ignore" != "yes" ]; then
        echo '{"mode":"dhcp","dns":""}'
        return
      fi
      norm=$(printf '%s' "$dns" | tr ';' ',' | tr -d ' ')
      case "$norm" in
        "1.1.1.1,1.0.0.1"|"1.1.1.1") mode="cloudflare" ;;
        "8.8.8.8,8.8.4.4"|"8.8.8.8") mode="google" ;;
        *) mode="custom" ;;
      esac
      jq -cn --arg m "$mode" --arg d "$dns" '{mode:$m, dns:$d}'
      ;;
    set)
      case "$mode" in
        dhcp)
          nmcli connection modify uuid "$uuid" ipv4.ignore-auto-dns no ipv4.dns "" >/dev/null 2>&1
          ;;
        cloudflare)
          nmcli connection modify uuid "$uuid" ipv4.ignore-auto-dns yes ipv4.dns "1.1.1.1,1.0.0.1" >/dev/null 2>&1
          ;;
        google)
          nmcli connection modify uuid "$uuid" ipv4.ignore-auto-dns yes ipv4.dns "8.8.8.8,8.8.4.4" >/dev/null 2>&1
          ;;
        custom)
          [ -z "$servers" ] && { echo '{"ok":false,"error":"servers required"}'; return; }
          nmcli connection modify uuid "$uuid" ipv4.ignore-auto-dns yes ipv4.dns "$servers" >/dev/null 2>&1
          ;;
        *) echo '{"ok":false,"error":"unknown mode"}'; return ;;
      esac
      nmcli device reapply "$d" >/dev/null 2>&1
      echo '{"ok":true}'
      ;;
    *)
      echo '{"ok":false,"error":"unknown dns action"}'
      ;;
  esac
}

cmd_scan() {
  local d
  d=$(dev)
  if [ -z "$d" ] || ! radio_on; then echo '{"ok":false}'; return; fi
  nmcli device wifi rescan ifname "$d" >/dev/null 2>&1
  sleep 2
  echo '{"ok":true}'
}

cmd_radio() {
  case "${1:-}" in on|off) ;; *) echo '{"ok":false}'; return ;; esac
  nmcli radio wifi "$1" >/dev/null 2>&1 && echo '{"ok":true}' || echo '{"ok":false}'
}

cmd_connect() {
  local ssid=$1 pw=${WIFI_PASS:-} d uuid out rc newuuid err
  d=$(dev)
  [ -z "$d" ] && { echo '{"ok":false,"error":"no wifi device"}'; return; }
  uuid=$(uuids_for_ssid "$ssid" | head -n1)

  if [ -n "$uuid" ]; then
    [ -n "$pw" ] && nmcli connection modify uuid "$uuid" wifi-sec.psk "$pw" >/dev/null 2>&1
    out=$(nmcli --wait 25 connection up uuid "$uuid" ifname "$d" 2>&1); rc=$?
  elif [ -n "$pw" ]; then
    out=$(nmcli --wait 25 device wifi connect "$ssid" password "$pw" ifname "$d" 2>&1); rc=$?
  else
    out=$(nmcli --wait 25 device wifi connect "$ssid" ifname "$d" 2>&1); rc=$?
  fi

  if [ "$rc" -eq 0 ]; then
    echo '{"ok":true}'
    return
  fi
  if [ -z "$uuid" ]; then
    newuuid=$(uuids_for_ssid "$ssid" | head -n1)
    [ -n "$newuuid" ] && nmcli connection delete uuid "$newuuid" >/dev/null 2>&1
  fi
  err=${out%%$'\n'*}; err=${err#Error: }
  jq -cn --arg e "$err" '{ok:false, error:$e}'
}

cmd_disconnect() {
  local d out
  d=$(dev)
  [ -z "$d" ] && { echo '{"ok":false,"error":"no wifi device"}'; return; }
  if out=$(nmcli device disconnect "$d" 2>&1); then
    echo '{"ok":true}'
  else
    jq -cn --arg e "${out#Error: }" '{ok:false, error:$e}'
  fi
}

cmd_forget() {
  local u n=0 fail=0
  while read -r u; do
    [ -z "$u" ] && continue
    nmcli connection delete uuid "$u" >/dev/null 2>&1 && n=$((n + 1)) || fail=1
  done < <(uuids_for_ssid "$1")
  if [ "$n" -gt 0 ] && [ "$fail" -eq 0 ]; then
    echo '{"ok":true}'
  else
    echo '{"ok":false,"error":"could not forget network"}'
  fi
}

cmd_traffic() {
  local d rx tx prx ptx
  d=$(dev)
  sample() {
    awk -v d="$d" '{sub(/:/, " ")} $1 == d {print $2, $10}' /proc/net/dev
  }
  if [ -z "$d" ]; then
    while true; do echo '{"up":0,"down":0,"upTotal":0,"downTotal":0}'; sleep 1; done
  fi
  read -r prx ptx < <(sample)
  prx=${prx:-0}; ptx=${ptx:-0}
  echo "{\"up\":0,\"down\":0,\"upTotal\":$ptx,\"downTotal\":$prx}"
  while sleep 1; do
    read -r rx tx < <(sample)
    rx=${rx:-$prx}; tx=${tx:-$ptx}
    echo "{\"up\":$((tx - ptx)),\"down\":$((rx - prx)),\"upTotal\":$tx,\"downTotal\":$rx}"
    prx=$rx; ptx=$tx
  done
}

case "${1:-}" in
  --status)     cmd_status ;;
  --list)       cmd_list ;;
  --ping)       cmd_ping ;;
  --speedtest)  cmd_speedtest ;;
  --qr)         cmd_qr "${2:-}" ;;
  --dns)        cmd_dns "${2:-get}" "${3:-}" "${4:-}" ;;
  --scan)       cmd_scan ;;
  --radio)      cmd_radio "${2:-}" ;;
  --connect)    cmd_connect "${2:-}" ;;
  --disconnect) cmd_disconnect ;;
  --forget)     cmd_forget "${2:-}" ;;
  --traffic)    cmd_traffic ;;
  *) echo '{"ok":false,"error":"unknown command"}' ;;
esac
