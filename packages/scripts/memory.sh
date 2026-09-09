#!/bin/sh

mem_total=$(awk '/^MemTotal/     {print $2}' /proc/meminfo)
mem_avail=$(awk '/^MemAvailable/ {print $2}' /proc/meminfo)
swap_total=$(awk '/^SwapTotal/   {print $2}' /proc/meminfo)
swap_free=$(awk '/^SwapFree/     {print $2}' /proc/meminfo)

mem_used=$(( mem_total - mem_avail ))
swap_used=$(( swap_total - swap_free ))

mem_used_mb=$(awk "BEGIN {printf \"%.0f\", $mem_used/1024}")
mem_total_mb=$(awk "BEGIN {printf \"%.0f\", $mem_total/1024}")
mem_pct=$(awk "BEGIN {printf \"%.0f\", $mem_used/$mem_total*100}")

if   [ "$mem_pct" -ge 90 ]; then icon="▰▰▰▰▰"
elif [ "$mem_pct" -ge 70 ]; then icon="▰▰▰▰▱"
elif [ "$mem_pct" -ge 50 ]; then icon="▰▰▰▱▱"
elif [ "$mem_pct" -ge 30 ]; then icon="▰▰▱▱▱"
elif [ "$mem_pct" -ge 10 ]; then icon="▰▱▱▱▱"
else                              icon="▱▱▱▱▱"
fi

out="${icon} ${mem_used_mb}/${mem_total_mb}MB | ${mem_pct}%"

if [ "$swap_total" -gt 0 ] && [ "$swap_used" -gt 0 ]; then
    swap_used_mb=$(awk "BEGIN {printf \"%.0f\", $swap_used/1024}")
    out="${out} | sw ${swap_used_mb}MB"
fi

echo "$out"
