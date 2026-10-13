# Wi-Fi

Эталонный плагин: на его устройство ориентируются остальные.

**Бар:** иконка Wi-Fi + имя сети (обрезается до `Theme.wifiBarMaxLength`) или
`Disconnected`. Зелёный — подключено, серый — нет. Клик открывает попап.

## Попап

- **Шапка:** `WI-FI` / `CONNECTED`. Кнопка спидометра — тест скорости, тумблер —
  радио Wi-Fi.
- **Инфо:** пинг и потери до шлюза, скорость и объём трафика, IP и шлюз.
  Пинг и трафик меряются только пока попап открыт.
- **DNS PROVIDER:** дропдаун провайдеров из `dns_providers.json`.
- **Сети:** список видимых сетей (текущая — полоса + галочка), сила сигнала,
  замок у защищённых. Клик — подключиться; защищённая несохранённая сеть
  открывает экран пароля. Список обновляется каждые 5 с, пересканирование —
  каждые 20 с.
- **Вложенные экраны** (`CONNECT`, `SPEED TEST`): стрелка назад или Escape.

## Файлы

| Файл | Что |
|---|---|
| `Wifi.qml` | Бар-модуль |
| `WifiService.qml` | Состояние, опросы, действия |
| `WifiPopup.qml` | Попап, переключение экранов по `WifiService.view` |
| `WifiHeader.qml`, `WifiInfoPanel.qml`, `WifiDnsSection.qml`, `WifiNetworkList.qml`, `NetworkRow.qml`, `SignalBars.qml` | Части главного экрана |
| `WifiPasswordView.qml`, `WifiSpeedtestView.qml` | Вложенные экраны |
| `dns_providers.json` | DNS-провайдеры |
| `scripts/wifi.sh` | NetworkManager (`nmcli`), `jq`, `curl` |

## Скрипт `wifi.sh`

`--status`, `--list`, `--scan`, `--radio on|off`, `--connect SSID` (пароль в
`$WIFI_PASS`), `--dns get`, `--dns set [SERVERS]`, `--ping`, `--speedtest`
(Cloudflare, Mbps), `--traffic` (поток раз в секунду). Форматы — в шапке скрипта.

## Настройка

`dns_providers.json` — `{ "label", "servers" }`, адреса через запятую, пустая
строка = DHCP. Подхватывается на лету. Текущий провайдер определяется по
активным адресам; не совпало — `CUSTOM`.

**IPC:** `qs -c taskbar ipc call wifi toggle` — открыть/закрыть попап.
