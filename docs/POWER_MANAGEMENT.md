> **[Русская версия](POWER_MANAGEMENT_RU.md)**

# Power Management — ASUS TUF Dash F15 / Arch Linux

## Why

The laptop consumed ~20W at idle. After tuning — ~10W. The main culprit was the RTX 3060 running continuously without power management.

Two tools are used: **TLP** and **supergfxctl**.

---

## TLP

**What it is:** A power management daemon. Automatically applies CPU, Wi-Fi, and device settings when switching between battery and AC.

**Install:**
```bash
sudo pacman -S tlp tlp-rdw
sudo systemctl enable --now tlp
sudo systemctl mask systemd-rfkill systemd-rfkill.socket
```

**Config:** `/etc/tlp.conf`

Current settings:
```ini
CPU_SCALING_GOVERNOR_ON_AC=powersave
CPU_SCALING_GOVERNOR_ON_BAT=powersave

CPU_ENERGY_PERF_POLICY_ON_AC=balance_power
CPU_ENERGY_PERF_POLICY_ON_BAT=power

CPU_MAX_PERF_ON_AC=80
CPU_MAX_PERF_ON_BAT=30

NMI_WATCHDOG=0

PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power

WIFI_PWR_ON_BAT=on
WIFI_PWR_ON_AC=off
```

**Apply without reboot:**
```bash
sudo tlp start
```

**Check status:**
```bash
tlp-stat -s
```

**Important:** Lines `START_CHARGE_THRESH_BAT0` and `STOP_CHARGE_THRESH_BAT0` must be commented out. If set, charging will stop at that threshold and the laptop won't charge above it.

---

## supergfxctl

**What it is:** A utility for ASUS laptops that manages GPU switching via `asus_wmi`. Allows fully powering off the discrete GPU.

**Install:**
```bash
yay -S supergfxctl
sudo systemctl enable --now supergfxd
```

**Modes:**

| Mode | What it does |
|------|-------------|
| `Integrated` | iGPU only. RTX 3060 fully off, D3cold. Maximum power savings. |
| `Hybrid` | Both GPUs. dGPU activates under load via PRIME offload. |
| `NvidiaNoModeset` | dGPU only without modesetting. Rarely needed. |

**Switching:**
```bash
# disable discrete GPU (maximum savings)
supergfxctl -m Integrated

# re-enable for games/rendering
supergfxctl -m Hybrid
```

Switching takes effect after reboot.

**Check current mode:**
```bash
supergfxctl -S
```

**Verify dGPU is off:**
```bash
nvidia-smi
# should return: No devices found
```

---

## Power Monitoring

**Current battery consumption:**
```bash
awk '{printf "%.2f W\n", $1/1000000}' /sys/class/power_supply/BAT0/power_now
```

**Battery status:**
```bash
cat /sys/class/power_supply/BAT0/status
# Charging / Discharging / Full
```

**GPU power (when active):**
```bash
nvidia-smi --query-gpu=power.draw,utilization.gpu --format=csv,noheader,nounits
```

**Live monitoring:**
```bash
watch -n 1 "awk '{printf \"%.2f W\n\", \$1/1000000}' /sys/class/power_supply/BAT0/power_now"
```

---

## Charging Not Working

First check if the system sees the adapter:
```bash
cat /sys/class/power_supply/AC0/online
# 1 = adapter detected, 0 = not detected
```

Check the charge threshold:
```bash
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
```

If not 100 — reset:
```bash
echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
```

Make sure thresholds are commented in `/etc/tlp.conf`:
```ini
# START_CHARGE_THRESH_BAT0=...
# STOP_CHARGE_THRESH_BAT0=...
```

Apply and reboot:
```bash
sudo tlp start
reboot
```

---

## Rollback

**Remove TLP:**
```bash
sudo systemctl stop tlp
sudo systemctl disable tlp
sudo systemctl unmask systemd-rfkill systemd-rfkill.socket
sudo pacman -Rns tlp tlp-rdw
```

**Remove supergfxctl:**
```bash
# first switch back to Hybrid to keep dGPU accessible
supergfxctl -m Hybrid
reboot

# after reboot
sudo systemctl stop supergfxd
sudo systemctl disable supergfxd
yay -Rns supergfxctl
reboot
```

**Reset EPP manually:**
```bash
echo balance_performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
```

---

## Results

| State | Power |
|-------|-------|
| Before tuning | ~20W idle |
| After (Integrated + TLP) | ~10W idle |
| RTX 3060 in Hybrid idle | +5–10W |
| RTX 3060 under load | up to 80W |

---

## License

[MIT](https://opensource.org/licenses/MIT)
