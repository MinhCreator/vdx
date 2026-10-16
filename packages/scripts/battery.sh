#!/bin/sh
# battery.sh — battery level and state, for the `battery` function

BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n 1)
[ -r "$BAT/status" ] || { echo "no battery"; exit 1; }

case $(cat "$BAT/status") in
    Charging)    icon="↑" ;;
    Discharging) icon="↓" ;;
    Full)        icon="=" ;;
    *)           icon="?" ;;
esac

# energy in µWh, power in µW: watts, and the time the energy lasts at this draw
awk -v icon="$icon" -v cap="$(cat "$BAT/capacity")" \
    -v energy="$(cat "$BAT/energy_now" 2>/dev/null || echo 0)" \
    -v power="$(cat "$BAT/power_now" 2>/dev/null || echo 0)" 'BEGIN {
    time = "--:--"
    if (power > 0) { t = energy / power; time = sprintf("%dh %02dm", int(t), int((t - int(t)) * 60)) }
    printf "%s %s%% | %.1fW | %s\n", icon, cap, power / 1000000, time
}'
