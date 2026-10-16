#!/bin/sh
# memory.sh — memory usage, for the `memory` function

awk '
/^MemTotal:/     { total = $2 }
/^MemAvailable:/ { avail = $2 }
/^SwapTotal:/    { swap_total = $2 }
/^SwapFree:/     { swap_free = $2 }
END {
    used = total - avail
    pct = int(used / total * 100 + 0.5)
    filled = pct >= 90 ? 5 : pct >= 70 ? 4 : pct >= 50 ? 3 : pct >= 30 ? 2 : pct >= 10 ? 1 : 0
    bar = ""
    for (i = 1; i <= 5; i++) bar = bar (i <= filled ? "▰" : "▱")
    out = sprintf("%s %.0f/%.0fMB | %d%%", bar, used / 1024, total / 1024, pct)
    swap = swap_total - swap_free
    if (swap > 0) out = out sprintf(" | sw %.0fMB", swap / 1024)
    print out
}' /proc/meminfo
