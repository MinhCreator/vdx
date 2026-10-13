#!/usr/bin/env bash
#
# battery.sh — waybar-compatible battery text for the bar (sysfs backend).
#
# Mirrors waybar's linux battery module for this config:
#   format          "{icon}  {capacity}"  (level icon by capacity/20, no % suffix)
#   format-charging "  {capacity}"
#   format-plugged  "  {capacity}"
#   states          warning 30 · critical 15
#
# Output is JSON: {"text":"<label>","class":"<class>"} where <class> carries the
# colour waybar would apply (charging green · critical red · warning yellow ·
# else foreground0). Prints {"text":""} when no battery is present (hidden).

set -euo pipefail

# --- locate the main battery (waybar: type == "Battery", skip scope == "Device")
battery=""
for d in /sys/class/power_supply/*; do
    [[ -f "$d/type" ]] || continue
    [[ "$(cat "$d/type")" == "Battery" ]] || continue
    if [[ -f "$d/scope" && "$(cat "$d/scope")" == "Device" ]]; then continue; fi
    if [[ -f "$d/capacity" || -f "$d/charge_now" || -f "$d/energy_now" ]]; then
        battery="$d"
        break
    fi
done

if [[ -z "$battery" ]]; then
    printf '{"text":""}\n'
    exit 0
fi

# --- capacity (waybar order: charge_now/charge_full, energy_now/energy_full, capacity)
capacity=""
if [[ -f "$battery/charge_now" && -f "$battery/charge_full" ]]; then
    now="$(cat "$battery/charge_now")"; full="$(cat "$battery/charge_full")"
    [[ "$full" -ne 0 ]] && capacity=$(( now * 100 / full ))
fi
if [[ -z "$capacity" && -f "$battery/energy_now" && -f "$battery/energy_full" ]]; then
    now="$(cat "$battery/energy_now")"; full="$(cat "$battery/energy_full")"
    [[ "$full" -ne 0 ]] && capacity=$(( now * 100 / full ))
fi
if [[ -z "$capacity" && -f "$battery/capacity" ]]; then
    capacity="$(cat "$battery/capacity")"
fi
capacity="${capacity:-0}"
(( capacity > 100 )) && capacity=100

# --- status (waybar reads the battery status, falling back to the adapter)
status="$(cat "$battery/status" 2>/dev/null || echo Unknown)"

# Mains adapter: among supplies exposing `online`, one that is currently online.
# (waybar's adapter loop is filesystem-order dependent; keying on the same
# observable fact — a connected AC adapter — keeps this deterministic.)
adapter=""
for d in /sys/class/power_supply/*; do
    if [[ -f "$d/online" && "$(cat "$d/online")" == "1" ]]; then adapter="$d"; fi
done

# Give "Plugged" priority over "Not charging"/"Discharging" (waybar TLP behaviour).
if [[ -n "$adapter" && ( "$status" == "Discharging" || "$status" == "Not charging" ) ]]; then
    astatus="$(cat "$adapter/status" 2>/dev/null || echo "")"
    if [[ "$astatus" != "Discharging" ]]; then
        status="Plugged"
    fi
fi

# waybar marks a stuck-at-100% charging battery as full.
if [[ "$capacity" -eq 100 && "$status" == "Charging" ]]; then
    status="Full"
fi

# --- format + class
ICON_CHARGING=""
ICON_PLUGGED=""
LEVEL_ICONS=("" "" "" "" "")

level_icon() {
    local idx=$(( capacity / 20 ))
    (( idx > 4 )) && idx=4
    printf '%s' "${LEVEL_ICONS[$idx]}"
}

case "$status" in
    Charging) text="$ICON_CHARGING  $capacity" ;;
    Plugged)  text="$ICON_PLUGGED  $capacity" ;;
    *)        text="$(level_icon)  $capacity" ;;
esac

# class priority mirrors the CSS cascade: charging > critical > warning > default.
if [[ "$status" == "Charging" ]]; then
    class="charging"
elif (( capacity <= 15 )); then
    class="critical"
elif (( capacity <= 30 )); then
    class="warning"
elif [[ "$status" == "Plugged" ]]; then
    class="plugged"
elif [[ "$status" == "Full" ]]; then
    class="full"
else
    class="discharging"
fi

printf '{"text":"%s","class":"%s"}\n' "$text" "$class"
