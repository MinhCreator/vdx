#!/bin/bash

run_system() {
    ( setsid systemctl "$@" >/dev/null 2>&1 & )
}

show() {
    printf '\0use-hot-keys\x1ftrue\n'
    printf 'Reboot\0info\x1freboot\n'
    printf 'Shutdown\0info\x1fpoweroff\n'
    printf 'Firmware Setup\0info\x1ffirmware\n'
}

case "${ROFI_RETV:-0}" in
    0) show ;;
    1)
        case "${ROFI_INFO:-}" in
            reboot)   run_system reboot ;;
            poweroff) run_system poweroff ;;
            firmware) run_system reboot --firmware-setup ;;
        esac
        ;;
    10) show ;;
    *) exit 0 ;;
esac
