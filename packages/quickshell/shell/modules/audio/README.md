# Audio

Устройства вывода/ввода и громкость через Pipewire.

**Бар:** иконка (динамик, наушники или mute) + громкость, при mute — `--`
красным. Колесо — громкость (`Theme.audioScrollStep`, максимум
`Theme.audioMaxPercent`). Клик открывает попап.

## Попап

- **Шапка:** `Audio`, `VOLUME 35%` / `OUTPUT MUTED` / `OFF`, тумблер
  выключает/включает сразу вывод и ввод.
- **OUTPUT / INPUT:** строка **Device** с выбором устройства и строка
  громкости (иконка — mute, ползунок до 100%, колесом в баре можно выше).
  Во **INPUT** ещё **Level** — живой уровень микрофона (`PwNodePeakMonitor`,
  dBFS −60…0; работает только при открытом попапе и включённом микрофоне).
- **APPLICATIONS (N):** потоки приложений, у каждого своя громкость и mute.
- В списке **Device** — строка на каждый порт устройства (`scripts/audio.sh`):
  у встроенной карты `SPEAKERS` и `HEADPHONES`, `INTERNAL MICROPHONE` и
  `MICROPHONE`. Динамики и встроенный микрофон видны всегда, остальные порты —
  когда подключены. Выбор ставит устройство по умолчанию и порт
  (`pactl set-sink-port` / `set-source-port`); одинаковые имена дополняются
  описанием устройства.
- Микрофон гарнитуры на ALC294 появляется только с правилом
  `system/etc/tmpfiles.d/headset-mic.conf` (переназначает пин 0x19).

## Файлы

| Файл | Что |
|---|---|
| `Audio.qml` | Бар-модуль |
| `AudioService.qml` | Pipewire-узлы, громкость, mute, порты |
| `AudioPopup.qml` | Попап |
| `AudioDeviceDropdown.qml` | Выбор устройства (`KitSelect`) |
| `AudioVolumeRow.qml` | Строка громкости узла |
| `scripts/audio.sh` | Активные порты через `pactl` (Pipewire их не отдаёт) |

## Скрипт `audio.sh`

Без аргументов: `{"<node.name>": {"port", "type"}}` для всех устройств.
Опрашивается раз в `Theme.audioPortIntervalMs`.

**IPC:** `qs -c shell ipc call audio toggle` — открыть/закрыть попап.
