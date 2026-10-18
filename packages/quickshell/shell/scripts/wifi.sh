#!/usr/bin/env bash
# wifi.sh — NetworkManager backend for modules/wifi/WifiService.qml.
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
#   --speedtest          {ok, down, up, ping, jitter, best, worst, lan, duration,
#                         ip, server, dev, gateway}  Mbps / ms / s; lan = gateway RTT
#   --traffic            {up, down}  bytes in the last second, one line a second
#   --listen             {ok}        one line per change NetworkManager reports (nmcli monitor),
#                                    for the service to re-read at once; runs until killed
#   --details            {ok, chan, freq, rate, security, bssid}   the access point in use
#   --saved              {ok, saved: [{uuid, ssid, active, autoconnect, priority, metered, dns}]}
#   --set UUID KEY VALUE {ok, error}   KEY autoconnect yes|no | priority N | metered yes|no|unknown
#   --disconnect         {ok, error}   the Wi-Fi device goes down until it is connected again
#   --hidden SSID        {ok, error}   connect to a hidden network; password in $WIFI_PASS

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

# The access point in use: channel, frequency, rate, security and BSSID.
cmd_details() {
  local line chan freq rate sec bssid
  line=$(nmcli -t --escape no -f IN-USE,CHAN,FREQ,RATE,SECURITY,BSSID device wifi list --rescan no 2>/dev/null |
         sed -n 's/^\*://p' | head -n1)
  [ -z "$line" ] && { error "not connected"; return; }
  IFS=: read -r chan freq rate sec bssid <<<"$line"
  jq -cn --arg chan "$chan" --arg freq "${freq% MHz}" --arg rate "$rate" \
         --arg sec "$sec" --arg bssid "$bssid" \
    '{ok:true, chan:$chan, freq:$freq, rate:$rate, security:$sec, bssid:$bssid}'
}

# The saved Wi-Fi profiles, the active one first, with the settings the Network page shows.
cmd_saved() {
  local d active uuid ssid auto prio metered
  d=$(dev)
  active=$([ -n "$d" ] && active_uuid "$d")
  saved_profiles | while IFS=$'\t' read -r uuid ssid; do
    { read -r auto; read -r prio; read -r metered; read -r ignore; read -r dns; } < <(
      nmcli -g connection.autoconnect,connection.autoconnect-priority,connection.metered,ipv4.ignore-auto-dns,ipv4.dns connection show uuid "$uuid" 2>/dev/null)
    jq -cn --arg uuid "$uuid" --arg ssid "$ssid" --arg auto "$auto" --arg prio "$prio" \
           --arg metered "$metered" --arg ignore "$ignore" --arg dns "$dns" \
           --argjson active "$([ "$uuid" = "$active" ] && echo true || echo false)" \
      '{uuid:$uuid, ssid:$ssid, active:$active, autoconnect:($auto == "yes"),
        priority:(($prio | tonumber?) // 0), metered:$metered,
        dns:(if $ignore == "yes" then $dns else "" end)}'
  done | jq -cs '{ok:true, saved: sort_by([(if .active then 0 else 1 end), .ssid])}'
}

# The device an active profile is up on, if any.
active_dev() { nmcli -t -f UUID,DEVICE connection show --active | awk -F: -v u="$1" '$1==u && $2!=""{print $2; exit}'; }

# One setting of a saved profile (wifi or ethernet); the values are checked before
# nmcli sees them. A network setting of an active profile is re-applied at once.
cmd_set() {
  local uuid=$1 key=$2 value=$3 extra=${4:-} addr gw dev
  local -a args
  [[ $uuid =~ ^[0-9a-f-]{36}$ ]] || { error "bad profile"; return; }
  case "$key" in
    autoconnect) [[ $value == yes || $value == no ]] || { error "expected yes|no"; return; }
                 args=(connection.autoconnect "$value") ;;
    priority)    [[ $value =~ ^-?[0-9]+$ ]] || { error "expected a number"; return; }
                 args=(connection.autoconnect-priority "$value") ;;
    metered)     [[ $value == yes || $value == no || $value == unknown ]] || { error "expected yes|no|unknown"; return; }
                 args=(connection.metered "$value") ;;
    dns)         if [ "$value" = auto ]; then
                   args=(ipv4.ignore-auto-dns no ipv4.dns "")
                 else
                   [[ $value =~ ^[0-9a-fA-F.:,]+$ ]] || { error "expected DNS servers, comma separated"; return; }
                   args=(ipv4.ignore-auto-dns yes ipv4.dns "$value")
                 fi ;;
    ipv4)        case "$value" in
                   auto)   args=(ipv4.method auto ipv4.addresses "" ipv4.gateway "") ;;
                   manual) read -r addr gw <<<"$extra"
                           [[ $addr =~ ^[0-9.]+/[0-9]{1,2}$ && $gw =~ ^[0-9.]+$ ]] || { error "expected ADDRESS/PREFIX GATEWAY"; return; }
                           args=(ipv4.method manual ipv4.addresses "$addr" ipv4.gateway "$gw") ;;
                   *)      error "expected auto|manual"; return ;;
                 esac ;;
    ipv6)        case "$value" in
                   auto) args=(ipv6.method auto) ;;
                   off)  args=(ipv6.method disabled) ;;
                   *)    error "expected auto|off"; return ;;
                 esac ;;
    *)           error "unknown setting: $key"; return ;;
  esac
  nmcli connection modify uuid "$uuid" "${args[@]}" >/dev/null 2>&1 || { error "could not change $key"; return; }
  case "$key" in
    dns|ipv4|ipv6) dev=$(active_dev "$uuid"); [ -n "$dev" ] && nmcli device reapply "$dev" >/dev/null 2>&1 ;;
  esac
  ok
}

# ---- ethernet ----
eth()      { nmcli -t -f DEVICE,TYPE device | awk -F: '$2=="ethernet"{print $1; exit}'; }
eth_uuid() { nmcli -t -f UUID,TYPE,DEVICE connection show | awk -F: -v d="$1" '$2=="802-3-ethernet" && $3==d{print $1; exit}'; }

# The wired device: its link and address, and the profile's settings.
cmd_ethernet() {
  local e uuid state carrier speed mac ip gw out
  local -a p
  e=$(eth)
  [ -z "$e" ] && { error "no ethernet device"; return; }
  case "${1:-}" in
    on)  uuid=$(eth_uuid "$e")
         if [ -z "$uuid" ]; then
           nmcli connection add type ethernet ifname "$e" con-name "Ethernet $e" autoconnect yes >/dev/null 2>&1 || { error "could not add the profile"; return; }
           uuid=$(eth_uuid "$e")
         fi
         out=$(nmcli --wait 20 connection up uuid "$uuid" 2>&1) && { ok; return; }
         out=${out%%$'\n'*}; error "${out#Error: }"; return ;;
    off) nmcli device disconnect "$e" >/dev/null 2>&1 && ok || error "could not disconnect" ; return ;;
    "") ;;
    *)   error "expected on|off"; return ;;
  esac
  state=$(dev_field "$e" GENERAL.STATE | sed 's/^[0-9]* (\(.*\))$/\1/')
  carrier=$(dev_field "$e" WIRED-PROPERTIES.CARRIER)
  speed=$(dev_field "$e" CAPABILITIES.SPEED)
  mac=$(dev_field "$e" GENERAL.HWADDR)
  ip=$(dev_field "$e" IP4.ADDRESS | head -n1)
  gw=$(dev_field "$e" IP4.GATEWAY | head -n1)
  uuid=$(eth_uuid "$e")
  p=()
  [ -n "$uuid" ] && mapfile -t p < <(nmcli -g connection.autoconnect,ipv4.method,ipv4.addresses,ipv4.gateway,ipv4.dns,ipv6.method,connection.metered connection show uuid "$uuid" 2>/dev/null)
  jq -cn --arg state "$state" --arg carrier "$carrier" --arg speed "$speed" --arg mac "$mac" \
         --arg ip "${ip%%/*}" --arg gw "$gw" --arg uuid "$uuid" \
         --arg auto "${p[0]:-yes}" --arg method "${p[1]:-auto}" --arg addr "${p[2]:-}" \
         --arg gwcfg "${p[3]:-}" --arg dns "${p[4]:-}" --arg ipv6 "${p[5]:-auto}" --arg metered "${p[6]:-unknown}" \
    '{ok:true, state:$state, carrier:($carrier == "yes"), speed:$speed, mac:$mac, ip:$ip, gateway:$gw,
      uuid:$uuid, autoconnect:($auto == "yes"), method:$method, addresses:$addr, gw:$gwcfg,
      dns:$dns, ipv6:($ipv6 != "disabled"), metered:$metered}'
}

# ---- hotspot: a Wi-Fi profile in AP mode on the Wi-Fi device, shared with dnsmasq ----
HOTSPOT=Hotspot
hotspot_uuid() { nmcli -t -f UUID,NAME,TYPE connection show | awk -F: -v n="$HOTSPOT" '$2==n && $3=="802-11-wireless"{print $1; exit}'; }

cmd_hotspot() {
  local d uuid supported=false active=false ssid channel clients=0
  d=$(dev)
  [ -z "$d" ] && { error "no wifi device"; return; }
  [ "$(dev_field "$d" WIFI-PROPERTIES.AP)" = yes ] && supported=true
  uuid=$(hotspot_uuid)
  if [ -n "$uuid" ]; then
    nmcli -t -f UUID connection show --active | grep -qx "$uuid" && active=true
    ssid=$(nmcli -g 802-11-wireless.ssid connection show uuid "$uuid" 2>/dev/null)
    channel=$(nmcli -g 802-11-wireless.channel connection show uuid "$uuid" 2>/dev/null)
  fi
  $active && clients=$(iw dev "$d" station dump 2>/dev/null | grep -c '^Station' || true)
  jq -cn --argjson supported "$supported" --argjson active "$active" --arg uuid "$uuid" \
         --arg ssid "${ssid:-$(uname -n)}" --arg channel "${channel:-0}" --argjson clients "${clients:-0}" \
    '{ok:true, supported:$supported, active:$active, uuid:$uuid, ssid:$ssid, channel:$channel, clients:$clients}'
}

cmd_hotspot_switch() {
  local uuid out
  uuid=$(hotspot_uuid)
  [ -z "$uuid" ] && { error "set a password first"; return; }
  case "$1" in
    on)  out=$(nmcli --wait 20 connection up uuid "$uuid" 2>&1) && { ok; return; }
         out=${out%%$'\n'*}; error "${out#Error: }" ;;
    off) nmcli connection down uuid "$uuid" >/dev/null 2>&1 && ok || error "could not stop the hotspot" ;;
    *)   error "expected on|off" ;;
  esac
}

# One setting of the hotspot: ssid, channel (auto|1|6|11) or password ($WIFI_PASS, 8 to 63
# characters). The profile is made with the password, and the other settings are set after.
cmd_hotspot_set() {
  local key=$1 value=$2 pw=${WIFI_PASS:-} d uuid
  uuid=$(hotspot_uuid)
  case "$key" in
    ssid)     [ ${#value} -ge 1 ] && [ ${#value} -le 32 ] || { error "a name is 1 to 32 characters"; return; } ;;
    channel)  case "$value" in auto) value=0 ;; 1|6|11) ;; *) error "expected auto|1|6|11"; return ;; esac ;;
    password) [ ${#pw} -ge 8 ] && [ ${#pw} -le 63 ] || { error "a password is 8 to 63 characters"; return; } ;;
    *)        error "unknown setting: $key"; return ;;
  esac
  if [ -z "$uuid" ]; then
    [ "$key" = password ] || { error "set a password first"; return; }
    d=$(dev)
    [ -z "$d" ] && { error "no wifi device"; return; }
    nmcli connection add type wifi ifname "$d" con-name "$HOTSPOT" autoconnect no ssid "$(uname -n)" \
      802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared ipv6.method ignore \
      wifi-sec.key-mgmt wpa-psk wifi-sec.proto rsn wifi-sec.pairwise ccmp wifi-sec.group ccmp \
      wifi-sec.psk "$pw" >/dev/null 2>&1 && ok || error "could not make the hotspot"
    return
  fi
  case "$key" in
    ssid)     nmcli connection modify uuid "$uuid" 802-11-wireless.ssid "$value" ;;
    channel)  nmcli connection modify uuid "$uuid" 802-11-wireless.channel "$value" ;;
    password) nmcli connection modify uuid "$uuid" wifi-sec.psk "$pw" ;;
  esac >/dev/null 2>&1 && ok || error "could not change $key"
}

cmd_disconnect() {
  local d
  d=$(dev)
  [ -n "$d" ] && nmcli device disconnect "$d" >/dev/null 2>&1 && ok || error "could not disconnect"
}

# A hidden network is named, not scanned: the profile a failed try leaves is dropped.
cmd_hidden() {
  local ssid=$1 pw=${WIFI_PASS:-} d uuid out
  d=$(dev)
  [ -z "$d" ] && { error "no wifi device"; return; }
  [ -z "$ssid" ] && { error "name the network"; return; }
  out=$(nmcli --wait 25 device wifi connect "$ssid" hidden yes ${pw:+password "$pw"} ifname "$d" 2>&1) && { ok; return; }
  uuid=$(uuid_for_ssid "$ssid")
  [ -n "$uuid" ] && nmcli connection delete uuid "$uuid" >/dev/null 2>&1
  out=${out%%$'\n'*}
  error "${out#Error: }"
}

# "rtt min/avg/max/mdev = 1.2/2.3/3.4/0.5 ms"
rtt_min()  { sed -nE 's|^rtt [^=]+= ([0-9.]+)/.*|\1|p'; }
rtt_avg()  { sed -nE 's|^rtt [^=]+= [0-9.]+/([0-9.]+)/.*|\1|p'; }
rtt_max()  { sed -nE 's|^rtt [^=]+= [0-9.]+/[0-9.]+/([0-9.]+)/.*|\1|p'; }
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
  local host=speed.cloudflare.com d gw="" ip pings lpings="" lfile t0 down up
  command -v curl >/dev/null || { error "curl is required"; return; }

  d=$(dev)
  [ -n "$d" ] && gw=$(dev_field "$d" IP4.GATEWAY | head -n1)
  lfile=$(mktemp)
  [ -n "$gw" ] && { ping -c 5 -W 1 -q "$gw" >"$lfile" 2>/dev/null & }
  ip=$(curl -s --max-time 3 https://api.ipify.org)
  pings=$(ping -c 5 -W 1 -q 1.1.1.1 2>/dev/null)
  wait
  lpings=$(<"$lfile")
  rm -f "$lfile"
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
         --argjson best "$(num "$(rtt_min <<<"$pings")")" \
         --argjson worst "$(num "$(rtt_max <<<"$pings")")" \
         --argjson lan "$(num "$(rtt_avg <<<"$lpings")")" \
         --argjson duration "$(awk -v a="$t0" -v b="$EPOCHREALTIME" 'BEGIN{print b-a}')" \
         --arg ip "$ip" --arg server "$host" --arg dev "$d" --arg gateway "$gw" \
    '{ok:true, down:($down*8/1e6), up:($up*8/1e6), ping:$ping, jitter:$jitter,
      best:$best, worst:$worst, lan:$lan, duration:$duration, ip:$ip, server:$server,
      dev:$dev, gateway:$gateway}'
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
    echo "{\"up\":$((tx - ptx)),\"down\":$((rx - prx))}"
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
  --details)   cmd_details ;;
  --saved)     cmd_saved ;;
  --set)       cmd_set "${2:-}" "${3:-}" "${4:-}" "${5:-}" ;;
  --ethernet)  cmd_ethernet "${2:-}" ;;
  --hotspot)   cmd_hotspot ;;
  --hotspot-switch) cmd_hotspot_switch "${2:-}" ;;
  --hotspot-set)    cmd_hotspot_set "${2:-}" "${3:-}" ;;
  --disconnect) cmd_disconnect ;;
  --hidden)    cmd_hidden "${2:-}" ;;
  --listen)    stdbuf -oL nmcli monitor 2>/dev/null | while read -r _; do ok; done ;;
  *)           error "unknown command: ${1:-}" ;;
esac
