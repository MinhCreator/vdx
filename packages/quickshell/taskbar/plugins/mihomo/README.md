# Mihomo

Управление прокси mihomo: сервис, провайдеры подписок, выбор сервера.

**Бар:** щит + `VPN`, зелёный — `mihomo.service` запущен. Клик открывает попап.

## Попап

- **Шапка:** `Mihomo`, `CONNECTED · <MODE>` / `DISCONNECTED`, метка
  `N SERVERS`, тумблер — запуск/остановка `mihomo.service`.
- **CONNECTION:** пинг текущего узла, его полное имя, провайдер и группа,
  трафик сейчас и за сессию.
- **Provider** — выбор подписки; **SERVERS (N)** — её серверы с пингом,
  текущий выделен, клик переключает.
- **Футер:** `Ping` (healthcheck серверов провайдера), `Update` (перекачать
  подписки); справа — открыть файл провайдера и `config.yaml` в
  `kitty -e nvim`.
- Выключен сервис или нет провайдеров — короткая фраза вместо списка; ошибки
  `Ping` / `Update` — красной строкой.

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
