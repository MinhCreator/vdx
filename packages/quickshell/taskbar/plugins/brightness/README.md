# Brightness

Подсветка экрана, ночной свет и затемнение через hyprsunset.

**Бар:** солнце + яркость; при включённом ночном свете — оранжевое. Колесо —
яркость (`Theme.brightnessScrollStep`). Клик открывает попап.

## Попап

- **Шапка:** `Display`, `BRIGHTNESS 80%` (+ `NIGHT LIGHT`), иконка — солнце
  или луна. Без тумблера — дисплей не выключается.
- **BRIGHTNESS** — подсветка 1–100%; **DIMMING** — затемнение гаммой ниже
  минимума подсветки (`Theme.dimGammaMin`–100%).
- **Night light** — строка с тумблером; когда включён: **TEMPERATURE**
  (`nightTemperatureMin`–`nightTemperatureMax` K) и кнопки пресетов.

## Как работает

hyprsunset запускается один раз (`hyprsunset -i`) и управляется через
`hyprctl hyprsunset temperature/identity/gamma` — без перезапусков. Ночной
свет, температура и затемнение сохраняются в
`~/.local/state/quickshell/by-shell/<id>/brightness.json` и применяются при
старте.

## Файлы

| Файл | Что |
|---|---|
| `Brightness.qml` | Бар-модуль |
| `BrightnessService.qml` | Подсветка, ночной свет, расписание, состояние |
| `BrightnessPopup.qml` | Попап |
| `night_light.json` | Пресеты и расписание |
| `scripts/brightness.sh` | `brightnessctl`, `hyprsunset` |

## Скрипт `brightness.sh`

`--get`, `--set N`, `--step ±N`, `--apply TEMPERATURE|off GAMMA`.

## Настройка `night_light.json`

- `presets` — `{ "label", "temperature" }`, кнопки в попапе.
- `schedule` — `{ "enabled", "start", "end" }` (`HH:mm`). Включённое расписание
  переключает ночной свет на границах интервала; тумблер в промежутке
  переопределяет его до следующей границы.

**IPC:** `qs -c taskbar ipc call brightness toggle` — открыть/закрыть попап.
