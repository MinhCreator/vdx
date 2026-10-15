# Wi-Fi

Эталонный модуль: на его устройство ориентируются остальные.

**Бар:** иконка Wi-Fi + имя сети (обрезается до `Theme.wifiBarMaxLength`) или
`--`. Зелёный — подключено, серый — нет. Клик открывает попап.

## Попап

- **Шапка:** имя сети, `CONNECTED` / `DISCONNECTED` / `OFF`, метка
  `N NEARBY`, тумблер — радио Wi-Fi.
- **CONNECTION** (только когда подключено): IP и шлюз, пинг и потери до шлюза,
  сигнал полоской с оценкой (Excellent / Good / Fair / Weak), трафик, строка
  **DNS** с выбором провайдера из `dns_providers.json`. Пинг и трафик
  меряются только пока попап открыт.
- **NETWORKS (N):** видимые сети; текущая — серая заливка, жирный шрифт,
  галочка. Замок у защищённых, полоски сигнала. Клик — подключиться;
  защищённая несохранённая сеть открывает экран пароля. Список обновляется
  каждые 5 с, пересканирование — каждые 20 с.
- **Футер:** `Rescan`, `Speed test`.
- **Вложенные экраны** `Connect` (пароль) и `Speed test` (скорость, задержка,
  сервер, `Run again`): кнопка `Back` или Escape.

## Файлы

| Файл | Что |
|---|---|
| `Wifi.qml` | Бар-модуль |
| `WifiService.qml` | Состояние, опросы, действия |
| `WifiPopup.qml` | Попап, переключение экранов по `WifiService.view` |
| `WifiOverview.qml`, `NetworkRow.qml`, `SignalBars.qml` | Главный экран |
| `WifiHeader.qml`, `WifiPasswordView.qml`, `WifiSpeedtestView.qml` | Вложенные экраны и их шапка |
| `dns_providers.json` | DNS-провайдеры |
| `scripts/wifi.sh` | NetworkManager (`nmcli`), `jq`, `curl` |

## Скрипт `wifi.sh`

`--status`, `--list`, `--scan`, `--radio on|off`, `--connect SSID` (пароль в
`$WIFI_PASS`), `--dns get`, `--dns set [SERVERS]`, `--ping`, `--speedtest`
(Cloudflare, Mbps), `--traffic` (поток раз в секунду). Форматы — в шапке скрипта.

## Настройка

`dns_providers.json` — `{ "label", "servers" }`, адреса через запятую, пустая
строка = DHCP. Подхватывается на лету. Текущий провайдер определяется по
активным адресам; не совпало — `Custom`.

**IPC:** `qs -c shell ipc call wifi toggle` — открыть/закрыть попап.
