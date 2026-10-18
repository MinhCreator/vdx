#!/bin/sh
# battery.sh — battery level and state, for the `battery` function

for BAT in /sys/class/power_supply/BAT*; do break; done
[ -r "$BAT/status" ] || { echo "no battery"; exit 1; }

case $(cat "$BAT/status") in
    Charging)    icon="↑" ;;
    Discharging) icon="↓" ;;
    Full)        icon="=" ;;
    *)           icon="?" ;;
esac

# energy in µWh, power in µW (a battery that counts charge in µAh and current in µA is
# converted with its voltage): watts, and the time the energy lasts at this draw
rd() { cat "$BAT/$1" 2>/dev/null || echo 0; }
awk -v icon="$icon" -v cap="$(rd capacity)" -v v="$(rd voltage_now)" \
    -v energy="$(rd energy_now)" -v charge="$(rd charge_now)" \
    -v power="$(rd power_now)" -v current="$(rd current_now)" 'BEGIN {
    if (energy == 0) energy = charge * v / 1000000
    if (power == 0) power = current * v / 1000000
    if (power < 0) power = -power
    time = "--:--"
    if (power > 0) { t = energy / power; time = sprintf("%dh %02dm", int(t), int((t - int(t)) * 60)) }
    printf "%s %s%% | %.1fW | %s\n", icon, cap, power / 1000000, time
}'
