"""Fake /sys and /proc trees for the detection tests."""

from __future__ import annotations

from pathlib import Path


def put(root: Path, rel: str, text: str = "") -> None:
    p = root / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(text + "\n")


def gpu(root: Path, slot: str, vendor: str, boot: bool, driver: str = "") -> None:
    d = f"sys/bus/pci/devices/{slot}"
    put(root, f"{d}/vendor", vendor)
    put(root, f"{d}/class", "0x030000")
    put(root, f"{d}/boot_vga", "1" if boot else "0")
    if driver:
        (root / "sys/bus/pci/drivers" / driver).mkdir(parents=True, exist_ok=True)
        (root / d / "driver").symlink_to(root / "sys/bus/pci/drivers" / driver)


def tuf(root: Path) -> None:
    """The ASUS TUF Dash F15 this repo was written on."""
    put(root, "sys/class/dmi/id/sys_vendor", "ASUSTeK COMPUTER INC.")
    put(root, "sys/class/dmi/id/product_name", "ASUS TUF Dash F15 FX516PM_FX516PM")
    put(root, "sys/class/dmi/id/board_name", "FX516PM")
    put(root, "sys/class/dmi/id/chassis_type", "10")
    put(root, "proc/cpuinfo", "processor\t: 0\nvendor_id\t: GenuineIntel")
    gpu(root, "0000:00:02.0", "0x8086", True, "i915")
    gpu(root, "0000:01:00.0", "0x10de", False, "nvidia")
    put(root, "sys/class/power_supply/BAT0/type", "Battery")
    put(root, "sys/class/power_supply/BAT0/charge_control_end_threshold", "80")
    put(root, "sys/class/power_supply/AC0/type", "Mains")
    put(root, "sys/firmware/acpi/platform_profile", "balanced")
    put(root, "sys/class/backlight/intel_backlight/brightness", "100")
    put(root, "sys/class/net/wlo1/wireless/.keep")
    put(root, "sys/class/bluetooth/hci0/.keep")
    put(root, "proc/asound/card0/codec#0", "Codec: Realtek ALC294\nAddress: 0")
    put(root, "proc/asound/card0/codec#2", "Codec: Intel Tigerlake HDMI")
    put(root, "sys/class/drm/card1-eDP-1/status", "connected")
    put(root, "sys/class/drm/card1-eDP-1/modes", "1920x1080")
    put(root, "sys/class/drm/card1-HDMI-A-2/status", "disconnected")
    put(root, "sys/devices/platform/asus-nb-wmi/dgpu_disable", "0")


def amd_desktop(root: Path) -> None:
    """A desktop: AMD CPU and GPU, two monitors, a wireless mouse's battery."""
    put(root, "sys/class/dmi/id/sys_vendor", "Micro-Star International Co., Ltd.")
    put(root, "sys/class/dmi/id/board_name", "MAG B550")
    put(root, "sys/class/dmi/id/chassis_type", "3")
    put(root, "proc/cpuinfo", "processor\t: 0\nvendor_id\t: AuthenticAMD")
    gpu(root, "0000:0c:00.0", "0x1002", True, "amdgpu")
    put(root, "sys/class/power_supply/hidpp_battery_0/type", "Battery")
    put(root, "sys/class/power_supply/hidpp_battery_0/scope", "Device")
    put(root, "proc/asound/card0/codec#0", "Codec: Realtek ALC897")
    for name, mode in (("DP-1", "2560x1440"), ("HDMI-A-1", "1920x1080")):
        put(root, f"sys/class/drm/card0-{name}/status", "connected")
        put(root, f"sys/class/drm/card0-{name}/modes", mode)
