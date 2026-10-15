#!/bin/sh
# battery.sh — battery level and state, for the `battery` function

BAT=/sys/class/power_supply/BAT0

bat_status=$(cat "$BAT/status")
bat_capacity=$(cat "$BAT/capacity")
bat_energy_now=$(cat "$BAT/energy_now")
bat_power_now=$(cat "$BAT/power_now")

bat_power_w=$(awk "BEGIN {printf \"%.1f\", $bat_power_now/1000000}")

bat_time="--:--"
if [ "$bat_power_now" -gt 0 ]; then
    bat_time=$(awk "BEGIN {
        t = $bat_energy_now / $bat_power_now
        h = int(t)
        m = int((t - h) * 60)
        printf \"%dh %02dm\", h, m
    }")
fi

case $bat_status in
    Charging)    bat_icon="↑" ;;
    Discharging) bat_icon="↓" ;;
    Full)        bat_icon="=" ;;
    *)           bat_icon="?" ;;
esac

echo "${bat_icon} ${bat_capacity}% | ${bat_power_w}W | ${bat_time}"
