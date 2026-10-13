# Mihomo

Управление прокси mihomo: сервис, провайдеры подписок, выбор сервера.

**Бар:** щит + `VPN`, зелёный — `mihomo.service` запущен. Клик открывает попап.

## Попап

- **Шапка:** `MIHOMO` / `CONNECTED`. Кнопки: PING (healthcheck серверов
  провайдера), UPDATE (перекачать подписки), шестерёнка (открыть
  `config.yaml` в `kitty -e nvim`). Тумблер — запуск/остановка сервиса.
- **CURRENT SERVER** — активный узел группы.
- **Инфо:** пинг текущего узла, провайдер, трафик, режим и группа.
- **PROVIDERS / SERVERS** — дропдауны. Выбор провайдера раскрывает его
  серверы; троеточие у провайдера открывает его файл в редакторе. У серверов —
  пинг.
- Выключен сервис или нет провайдеров — `MIHOMO IS OFF` / `NO PROVIDERS`.
- Ошибки PING/UPDATE — красной строкой внизу.

## Файлы

| Файл | Что |
|---|---|
| `Mihomo.qml` | Бар-модуль |
| `MihomoService.qml` | Состояние, опросы, действия |
| `MihomoPopup.qml` | Попап |
| `scripts/mihomo.sh` | REST mihomo (`127.0.0.1:9090`) и менеджер подписок |

## Скрипт `mihomo.sh`

`--status`, `--providers`, `--nodes P`, `--select NODE`, `--ping P`, `--update`,
`--traffic`, `--config-path`, `--path P`, `--toggle`. Провайдеры добавляются
правкой `subscriptions.json` (менеджер `packages/scripts/vpn/manager.py`
пересобирает `config.yaml`). Группа — `Theme.mihomoGroup`.

**IPC:** `qs -c taskbar ipc call mihomo toggle` — открыть/закрыть попап.
