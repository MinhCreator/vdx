"""dotfiles installer — what this machine is: hardware from /sys and /proc, no root, no lspci.

Every reader takes the filesystem root, so tests can point it at a fake tree.
`hardware()` is what the profile saves; `traits()` is derived from it;
`environment()` is the system around it (distro, Hyprland, shell), never saved.
"""

from __future__ import annotations

import grp
import os
import pwd
import re
import shutil
import subprocess
from pathlib import Path

PCI_VENDORS = {"0x8086": "intel", "0x1002": "amd", "0x10de": "nvidia"}
CPU_VENDORS = {"GenuineIntel": "intel", "AuthenticAMD": "amd"}
# /sys/class/dmi/id/chassis_type (SMBIOS): portable kinds, the rest of the known ones are desktops
LAPTOP_CHASSIS = {8, 9, 10, 11, 14, 30, 31, 32}
DESKTOP_CHASSIS = {3, 4, 5, 6, 7, 13, 15, 16, 35, 36}
INTERNAL_OUTPUT = re.compile(r"^(eDP|LVDS|DSI)")

# Fixes for one exact machine. A quirk applies only when every condition
# holds: they write to hardware registers that mean something else elsewhere.
QUIRKS = {
    "asus-fx516pm-headset-mic": {
        "about": "headset mic on the ALC294 combo jack (ASUS TUF Dash F15)",
        "board": "FX516PM",
        "codec": (0, 0, "Realtek ALC294"),       # card, codec index (hwC0D0), name
    },
}


def read(path: Path, default: str = "") -> str:
    try:
        return path.read_text().strip()
    except (OSError, UnicodeDecodeError):
        return default


# --------------------------------------------------------------------------- hardware

def dmi(root: Path) -> dict:
    d = root / "sys/class/dmi/id"
    chassis = read(d / "chassis_type")
    kind = int(chassis) if chassis.isdigit() else 0
    return {
        "vendor": read(d / "sys_vendor"),
        "product": read(d / "product_name"),
        "board": read(d / "board_name"),
        "chassis": "laptop" if kind in LAPTOP_CHASSIS else "desktop" if kind in DESKTOP_CHASSIS else "unknown",
    }


def cpu(root: Path) -> str:
    m = re.search(r"^vendor_id\s*:\s*(\S+)", read(root / "proc/cpuinfo"), re.M)
    return CPU_VENDORS.get(m.group(1), m.group(1).lower()) if m else "unknown"


def gpus(root: Path) -> list[dict]:
    """Display controllers (PCI class 0x03xxxx), the boot one first."""
    out = []
    for d in sorted((root / "sys/bus/pci/devices").glob("*")):
        if not read(d / "class").startswith("0x03"):
            continue
        vendor = read(d / "vendor")
        driver = d / "driver"
        out.append({
            "vendor": PCI_VENDORS.get(vendor, vendor),
            "pci": d.name,
            "driver": os.path.basename(os.readlink(driver)) if driver.is_symlink() else "",
            "boot": read(d / "boot_vga") == "1",
        })
    return sorted(out, key=lambda g: not g["boot"])


def battery(root: Path) -> str:
    """The main battery's name (BAT0, BAT1, ...): type Battery, not a peripheral's."""
    for d in sorted((root / "sys/class/power_supply").glob("*")):
        if read(d / "type") == "Battery" and read(d / "scope") != "Device":
            return d.name
    return ""


def codecs(root: Path) -> list[dict]:
    out = []
    for f in sorted((root / "proc/asound").glob("card[0-9]*/codec#[0-9]*")):
        m = re.search(r"^Codec:\s*(.+)$", read(f), re.M)
        if m:
            out.append({"card": int(f.parent.name[4:]), "index": int(f.name[6:]), "name": m.group(1).strip()})
    return out


def monitors(root: Path) -> list[dict]:
    """Connected outputs by their DRM name (card1-eDP-1 -> eDP-1, as Hyprland calls it)."""
    out = []
    for c in sorted((root / "sys/class/drm").glob("card[0-9]*-*")):
        if read(c / "status") != "connected":
            continue
        card, name = c.name.split("-", 1)
        modes = read(c / "modes").splitlines()
        out.append({"name": name, "card": card, "mode": modes[0] if modes else "",
                    "internal": bool(INTERNAL_OUTPUT.match(name))})
    return out


def hardware(root: Path = Path("/")) -> dict:
    """Everything the profile saves about this machine."""
    bat = battery(root)
    backlights = sorted(p.name for p in (root / "sys/class/backlight").glob("*"))
    wifi = sorted(p.parent.name for p in (root / "sys/class/net").glob("*/wireless"))
    return {
        **dmi(root),
        "cpu": cpu(root),
        "gpus": gpus(root),
        # ASUS laptops can take the dGPU off the PCI bus (supergfxctl Integrated):
        # then it's missing from `gpus`, but this says it's there
        "dgpu_off": read(root / "sys/devices/platform/asus-nb-wmi/dgpu_disable") == "1",
        "battery": bat,
        "charge_limit": bool(bat) and (root / "sys/class/power_supply" / bat / "charge_control_end_threshold").exists(),
        "platform_profile": (root / "sys/firmware/acpi/platform_profile").exists(),
        "backlight": backlights[0] if backlights else "",
        "wifi": wifi[0] if wifi else "",
        "bluetooth": any((root / "sys/class/bluetooth").glob("hci*")),
        "codecs": codecs(root),
        "monitors": monitors(root),
    }


# --------------------------------------------------------------------------- traits

def quirks(hw: dict) -> list[str]:
    out = []
    for name, q in QUIRKS.items():
        if q.get("board") and hw.get("board") != q["board"]:
            continue
        if q.get("codec"):
            card, index, codec = q["codec"]
            if not any(c["card"] == card and c["index"] == index and c["name"] == codec for c in hw.get("codecs", [])):
                continue
        out.append(name)
    return out


def traits(hw: dict) -> dict:
    """What the installer decides by: derived from the hardware, never saved."""
    vendors = list(dict.fromkeys(g["vendor"] for g in hw.get("gpus", [])))
    return {
        "gpu": vendors,
        "hybrid": len(hw.get("gpus", [])) > 1 and "nvidia" in vendors,
        "laptop": hw.get("chassis") == "laptop" or bool(hw.get("battery")),
        "asus": hw.get("vendor", "").upper().startswith("ASUS"),
        "quirks": quirks(hw),
    }


# --------------------------------------------------------------------------- environment

def environment(root: Path = Path("/")) -> dict:
    """The system around the hardware: checked at every run, never saved."""
    osr = dict(re.findall(r'^(\w+)="?([^"\n]*)"?$', read(root / "etc/os-release"), re.M))
    hypr = ""
    if shutil.which("Hyprland"):
        r = subprocess.run(["Hyprland", "--version"], capture_output=True, text=True)
        m = re.search(r"Hyprland (\d+\.\d+\.\d+)", r.stdout)
        hypr = m.group(1) if m else ""
    user = pwd.getpwuid(os.getuid())
    groups = sorted(g.gr_name for g in grp.getgrall() if user.pw_name in g.gr_mem)
    return {
        "distro": osr.get("ID", "unknown"),
        "hyprland": hypr,
        "aur_helper": next((h for h in ("paru", "yay") if shutil.which(h)), ""),
        "shell": user.pw_shell,
        "groups": groups,
        "root": os.getuid() == 0,
    }
