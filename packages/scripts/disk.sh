#!/bin/sh
# disk.sh — disk usage, for the `disk` function

df -h --output=size,used,pcent,target -x tmpfs -x devtmpfs -x efivarfs 2>/dev/null |
    tail -n +2 | sort -k4 |
    awk '{
        pct = $3 + 0
        label = $4 == "/home" ? "~" : $4 == "/boot/efi" ? "efi" : $4 == "/boot" ? "boot" : $4
        filled = pct >= 90 ? 5 : pct >= 70 ? 4 : pct >= 50 ? 3 : pct >= 30 ? 2 : pct >= 10 ? 1 : 0
        bar = ""
        for (i = 1; i <= 5; i++) bar = bar (i <= filled ? "▰" : "▱")
        printf "%s  %-16s  %-12s  %d%%\n", bar, label, $2 "/" $1, pct
    }'
