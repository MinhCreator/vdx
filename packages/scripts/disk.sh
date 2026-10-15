#!/bin/sh
# disk.sh — disk usage, for the `disk` function

df -h --output=source,size,used,avail,pcent,target \
    -x tmpfs -x devtmpfs -x efivarfs 2>/dev/null \
    | tail -n +2 \
    | sort -k6 \
    | while IFS= read -r line; do

    used=$(echo  "$line" | awk '{print $3}')
    total=$(echo "$line" | awk '{print $2}')
    pct=$(echo   "$line" | awk '{print $5}' | tr -d '%')
    mount=$(echo "$line" | awk '{print $6}')

    case $mount in
        /)         label="/" ;;
        /home)     label="~" ;;
        /boot/efi) label="efi" ;;
        /boot)     label="boot" ;;
        *)         label="$mount" ;;
    esac

    if   [ "$pct" -ge 90 ]; then icon="▰▰▰▰▰"
    elif [ "$pct" -ge 70 ]; then icon="▰▰▰▰▱"
    elif [ "$pct" -ge 50 ]; then icon="▰▰▰▱▱"
    elif [ "$pct" -ge 30 ]; then icon="▰▰▱▱▱"
    elif [ "$pct" -ge 10 ]; then icon="▰▱▱▱▱"
    else                          icon="▱▱▱▱▱"
    fi

    printf "%s  %-16s  %-12s  %s%%\n" "$icon" "$label" "${used}/${total}" "$pct"
done
