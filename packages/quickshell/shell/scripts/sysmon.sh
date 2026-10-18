#!/usr/bin/env bash
#
# sysmon.sh [cpu] — one snapshot of system counters as JSON; rates and
# percentages come from the difference of two snapshots (SysmonService).
# With `cpu`, only {"cpu": [...]}.
#   {"cpu": [[total, idle], ...]  (first: all cores, then each core),
#    "freq": 2400, "load": [0.5, 0.4, 0.3], "uptime": 12345,
#    "mem": {"total": B, "available": B, "swapTotal": B, "swapFree": B},
#    "temps": {"cpu": 45, "nvme": [40, 38], "wifi": 42}, "fans": [2400, 2300],
#    "igpu": {"cur": 400, "max": 1350},
#    "dgpu": {"state": "active|suspended|none", "name": "...", "util": 3, "memUsed": MiB,
#             "memTotal": MiB, "temp": 49, "power": 11.9},
#    "net": {"iface": "wlo1", "rx": B, "tx": B}, "io": {"read": B, "write": B},
#    "disks": [{"mount": "/", "size": B, "used": B}, ...]}
# The NVIDIA GPU is asked only when it is already awake: nvidia-smi wakes it.

set -u

cpu=$(awk '/^cpu/ { idle = $5 + $6; t = 0; for (i = 2; i <= 9; i++) t += $i; printf "%s[%d,%d]", (n++ ? "," : ""), t, idle }' /proc/stat)
# `cpu`: just the cpu counters, cheap enough for the bar every few seconds
[ "${1:-}" = cpu ] && { printf '{"cpu":[%s]}\n' "$cpu"; exit 0; }

freq=$(awk -F: '/^cpu MHz/ { s += $2; n++ } END { printf "%d", n ? s / n : 0 }' /proc/cpuinfo)
read -r l1 l5 l15 _ </proc/loadavg
uptime=$(cut -d. -f1 /proc/uptime)
mem=$(awk '/^(MemTotal|MemAvailable|SwapTotal|SwapFree):/ { v[$1] = $2 * 1024 }
  END { printf "{\"total\":%d,\"available\":%d,\"swapTotal\":%d,\"swapFree\":%d}", v["MemTotal:"], v["MemAvailable:"], v["SwapTotal:"], v["SwapFree:"] }' /proc/meminfo)

# temperatures (°C) and fans by hwmon name
tcpu=null; twifi=null; nvme=(); fans=()
for h in /sys/class/hwmon/hwmon*; do
  case $(cat "$h/name" 2>/dev/null) in
    coretemp|k10temp|zenpower) tcpu=$(( $(cat "$h/temp1_input") / 1000 )) ;;
    nvme) nvme+=("$(( $(cat "$h/temp1_input") / 1000 ))") ;;
    iwlwifi*) twifi=$(( $(cat "$h/temp1_input" 2>/dev/null || echo 0) / 1000 )) ;;
  esac
  for f in "$h"/fan*_input; do [ -r "$f" ] && fans+=("$(cat "$f")"); done
done
join() { local IFS=,; echo "$*"; }

igpu=null
for c in /sys/class/drm/card*; do
  [ -r "$c/gt_cur_freq_mhz" ] && igpu="{\"cur\":$(cat "$c/gt_cur_freq_mhz"),\"max\":$(cat "$c/gt_max_freq_mhz")}" && break
done

dgpu='{"state":"none"}'
for d in /sys/bus/pci/devices/*; do
  [ "$(cat "$d/vendor" 2>/dev/null)" = 0x10de ] && [ "$(cat "$d/class")" = 0x030000 ] || continue
  state=$(cat "$d/power/runtime_status" 2>/dev/null || echo active)
  if [ "$state" = active ] && command -v nvidia-smi >/dev/null; then
    IFS=, read -r name util mu mt temp power < <(nvidia-smi --query-gpu=name,utilization.gpu,memory.used,memory.total,temperature.gpu,power.draw \
      --format=csv,noheader,nounits 2>/dev/null | head -1)
    dgpu=$(jq -cn --arg name "${name:-NVIDIA}" --arg u "${util// /}" --arg mu "${mu// /}" --arg mt "${mt// /}" --arg t "${temp// /}" --arg p "${power// /}" \
      '{state: "active", name: $name, util: ($u|tonumber? // 0), memUsed: ($mu|tonumber? // 0), memTotal: ($mt|tonumber? // 0),
        temp: ($t|tonumber? // null), power: ($p|tonumber? // null)}')
  else
    dgpu="{\"state\":\"$state\"}"
  fi
  break
done

iface=$(ip route show default 2>/dev/null | awk '{ print $5; exit }')
net=$(awk -v i="${iface:-}" -F'[: ]+' '$2 == i { printf "{\"iface\":\"%s\",\"rx\":%d,\"tx\":%d}", i, $3, $11 }' /proc/net/dev)
io=$(awk '$3 ~ /^(nvme[0-9]+n[0-9]+|sd[a-z]+|vd[a-z]+|mmcblk[0-9]+)$/ { r += $6; w += $10 } END { printf "{\"read\":%d,\"write\":%d}", r * 512, w * 512 }' /proc/diskstats)
disks=$(df -B1 --output=target,size,used -x tmpfs -x devtmpfs -x efivarfs -x overlay 2>/dev/null |
  awk 'NR > 1 { printf "%s{\"mount\":\"%s\",\"size\":%d,\"used\":%d}", (n++ ? "," : ""), $1, $2, $3 }')

printf '{"cpu":[%s],"freq":%s,"load":[%s,%s,%s],"uptime":%s,"mem":%s,"temps":{"cpu":%s,"nvme":[%s],"wifi":%s},"fans":[%s],"igpu":%s,"dgpu":%s,"net":%s,"io":%s,"disks":[%s]}\n' \
  "$cpu" "$freq" "$l1" "$l5" "$l15" "$uptime" "$mem" "$tcpu" "$(join "${nvme[@]}")" "$twifi" "$(join "${fans[@]}")" \
  "$igpu" "$dgpu" "${net:-null}" "$io" "$disks"
