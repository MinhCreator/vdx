# Battery

Батарея, лимит зарядки, профиль питания, режим GPU и энергосбережение.

**Бар:** иконка уровня / зарядки / вилки + заряд. Жёлтый ≤ `batteryWarning`,
красный ≤ `batteryCritical`, зелёный — зарядка. Энергосбережение — листочек,
зелёный. Клик открывает попап.

## Попап

- **Шапка:** `Battery`, `CHARGING · 1:20 TO 80%` / `DISCHARGING · 3:40 LEFT` /
  `PLUGGED IN · LIMIT 80%`, метка заряда цветом уровня.
- **CHARGE:** полоска заряда, мощность; **Health** (`energy_full /
  energy_full_design`), **Cycles**, **Energy** (текущая / паспортная).
- **POWER:** **Power saver** — тумблер (профиль `Theme.powerSaverProfile`,
  выключение возвращает прежний), **Charge limit** (`Theme.batteryLimits`),
  **Profile** (из `platform_profile_choices`), **GPU** (Integrated / Hybrid
  через supergfxctl; ожидающая смена — оранжевая подсказка).
- Уведомления о низком заряде на `Theme.batteryNotifyLevels` (`notify-send`).

## Права

Лимит и профиль пишутся в sysfs, нужно правило
`system/etc/tmpfiles.d/quickshell-power.conf` (корень dotfiles):

```
./install.py system install
```

Лимит сбрасывается при перезагрузке — сервис хранит выбранный в
`statePath("battery.json")` и выставляет при старте. TLP меняет профиль при
смене питания (`PLATFORM_PROFILE_ON_AC/BAT` в `/etc/tlp.conf`) — это снимает
энергосбережение.

## Файлы

| Файл | Что |
|---|---|
| `Battery.qml` | Бар-модуль |
| `BatteryService.qml` | Состояние, действия, уведомления |
| `BatteryPopup.qml` | Попап |
| `scripts/battery.sh` | sysfs, `supergfxctl` |

## Скрипт `battery.sh`

`--status`, `--threshold N`, `--profile NAME`, `--gpu`, `--gpu-mode MODE`.

**IPC:** `qs -c taskbar ipc call battery toggle` — открыть/закрыть попап.
