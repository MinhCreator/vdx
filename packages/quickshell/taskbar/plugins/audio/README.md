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
- Имена устройств — описание активного порта (`SPEAKERS`, `HEADPHONES`,
  `MICROPHONE`); одинаковые дополняются описанием устройства.

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

**IPC:** `qs -c taskbar ipc call audio toggle` — открыть/закрыть попап.
