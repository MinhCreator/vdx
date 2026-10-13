> **[English version](POWER_MANAGEMENT.md)**

# Управление питанием — ASUS TUF Dash F15 / Arch Linux

## Зачем

Ноутбук потреблял ~20W в idle. После настройки — ~10W. Основная причина — RTX 3060 работала постоянно без управления питанием.

Установлены два инструмента: **TLP** и **supergfxctl**.

---

## TLP

**Что это:** демон управления питанием. Автоматически применяет настройки CPU, Wi-Fi и других устройств при переключении между батареей и сетью.

**Установка:**
```bash
sudo pacman -S tlp tlp-rdw
sudo systemctl enable --now tlp
sudo systemctl mask systemd-rfkill systemd-rfkill.socket
```

**Конфиг:** `system/etc/tlp.d/99-dotfiles.conf` в репозитории → `/etc/tlp.d/` (`./install.py system install`). `/etc/tlp.conf` держи в дефолтах пакета: он читается после drop-in и перекрывает его.

Текущие настройки:
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

**Применить без перезагрузки:**
```bash
sudo tlp start
```

**Проверить статус:**
```bash
tlp-stat -s
```

**Важно:** строки `START_CHARGE_THRESH_BAT0` и `STOP_CHARGE_THRESH_BAT0` должны быть закомментированы. Если они выставлены — зарядка остановится на указанном пороге и ноутбук перестанет заряжаться выше него.

---

## supergfxctl

**Что это:** утилита для ASUS-ноутбуков, управляет переключением GPU через `asus_wmi`. Позволяет полностью выключить дискретную карту.

**Установка:**
```bash
yay -S supergfxctl
sudo systemctl enable --now supergfxd
```

**Режимы:**

| Режим | Что делает |
|-------|-----------|
| `Integrated` | Только iGPU. RTX 3060 полностью выключена, D3cold. Максимальная экономия. |
| `Hybrid` | Оба GPU. dGPU включается под нагрузку через PRIME offload. |
| `NvidiaNoModeset` | Только dGPU без modesetting. Редко нужен. |

**Переключение:**
```bash
# выключить дискретку (максимальная экономия)
supergfxctl -m Integrated

# включить обратно для игр/рендеринга
supergfxctl -m Hybrid
```

Переключение вступает в силу после перезагрузки.

**Проверить текущий режим:**
```bash
supergfxctl -S
```

**Проверить что dGPU выключена:**
```bash
nvidia-smi
# должна быть ошибка: No devices found
```

---

## Мониторинг потребления

**Текущее потребление батареи:**
```bash
awk '{printf "%.2f W\n", $1/1000000}' /sys/class/power_supply/BAT0/power_now
```

**Статус батареи:**
```bash
cat /sys/class/power_supply/BAT0/status
# Charging / Discharging / Full
```

**Потребление GPU (когда активна):**
```bash
nvidia-smi --query-gpu=power.draw,utilization.gpu --format=csv,noheader,nounits
```

**Наблюдение в реальном времени:**
```bash
watch -n 1 "awk '{printf \"%.2f W\n\", \$1/1000000}' /sys/class/power_supply/BAT0/power_now"
```

---

## Зарядка перестала работать

Проверить видит ли система адаптер:
```bash
cat /sys/class/power_supply/AC0/online
# 1 = адаптер определяется, 0 = не видит
```

Проверить порог зарядки:
```bash
cat /sys/class/power_supply/BAT0/charge_control_end_threshold
```

Если там не 100 — сбросить:
```bash
echo 100 | sudo tee /sys/class/power_supply/BAT0/charge_control_end_threshold
```

Убедиться что в `/etc/tlp.conf` закомментированы пороги:
```ini
# START_CHARGE_THRESH_BAT0=...
# STOP_CHARGE_THRESH_BAT0=...
```

Применить и перезагрузиться:
```bash
sudo tlp start
reboot
```

---

## Откат

**Удалить TLP:**
```bash
sudo systemctl stop tlp
sudo systemctl disable tlp
sudo systemctl unmask systemd-rfkill systemd-rfkill.socket
sudo pacman -Rns tlp tlp-rdw
```

**Удалить supergfxctl:**
```bash
# сначала вернуть Hybrid чтобы не потерять dGPU
supergfxctl -m Hybrid
reboot

# после ребута
sudo systemctl stop supergfxd
sudo systemctl disable supergfxd
yay -Rns supergfxctl
reboot
```

**Сбросить EPP вручную:**
```bash
echo balance_performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/energy_performance_preference
```

---

## Итоговые цифры

| Состояние | Потребление |
|-----------|------------|
| До настройки | ~20W idle |
| После (Integrated + TLP) | ~10W idle |
| RTX 3060 в Hybrid idle | +5–10W |
| RTX 3060 под нагрузкой | до 80W |

---

## Лицензия

[MIT](https://opensource.org/licenses/MIT)
