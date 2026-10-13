# Audio

Устройства вывода/ввода и громкость через Pipewire.

**Бар:** иконка (динамик, наушники или mute) + громкость, при mute — `--`
красным. Колесо — громкость (`Theme.audioScrollStep`, максимум
`Theme.audioMaxPercent`). Клик открывает попап.

## Попап

- **Шапка:** `AUDIO`, под ним `SPEAKERS · 35%` / `OUTPUT MUTED` / `OFF`.
  Тумблер выключает/включает сразу вывод и ввод.
- **OUTPUT / INPUT:** дропдаун устройства + строка громкости (кнопка mute,
  ползунок, процент). Ползунок — до 100%, колесом в баре можно выше.
- **APPLICATIONS: N:** потоки приложений, у каждого своя громкость и mute.
- Имена устройств — описание активного порта (`SPEAKERS`, `HEADPHONES`,
  `MICROPHONE`); одинаковые имена дополняются описанием устройства.

## Файлы

| Файл | Что |
|---|---|
| `Audio.qml` | Бар-модуль |
| `AudioService.qml` | Pipewire-узлы, громкость, mute, порты |
| `AudioPopup.qml` | Попап |
| `AudioDeviceDropdown.qml` | Дропдаун устройства |
| `AudioVolumeRow.qml` | Строка громкости узла |
| `scripts/audio.sh` | Активные порты через `pactl` (Pipewire их не отдаёт) |

## Скрипт `audio.sh`

Без аргументов: `{"<node.name>": {"port", "type"}}` для всех устройств.
Опрашивается раз в `Theme.audioPortIntervalMs`.

**IPC:** `qs -c taskbar ipc call audio toggle` — открыть/закрыть попап.
