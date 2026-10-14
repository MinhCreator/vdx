#!/bin/bash
# rofi mode "boot": power menu (lock, reboot, power off)

run_system() {
    ( setsid systemctl "$@" >/dev/null 2>&1 & )
}

show() {
    printf '\0use-hot-keys\x1ftrue\n'
    printf 'LOCK\0info\x1flock\n'
    printf 'REBOOT\0info\x1freboot\n'
    printf 'SHUTDOWN\0info\x1fpoweroff\n'
}

case "${ROFI_RETV:-0}" in
    0) show ;;
    1)
        case "${ROFI_INFO:-}" in
            lock)     swaylock ;;
            reboot)   run_system reboot ;;
            poweroff) run_system poweroff ;;
        esac
        ;;
    10) show ;;
    *) exit 0 ;;
esac
