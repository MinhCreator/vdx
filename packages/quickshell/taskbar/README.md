# quickshell — bar (конфиг `taskbar`)

1-в-1 перенос waybar-панели (`packages/waybar`) на Quickshell v0.3.
Конфиг живёт в `~/.config/quickshell/taskbar/` — это корень `qs` для
`qs -c taskbar`. `~/.config/quickshell` — символическая ссылка на
`packages/quickshell`, поэтому править можно прямо в репозитории.

## Структура

```
taskbar/
├─ shell.qml              точка входа (Variants -> Bar, watcher темы)
├─ README.md
├─ docs/                  PLUGIN.md, PLUGIN_STYLE.md
├─ scripts/               *.sh, бэкенд модулей (JSON в stdout)
├─ config/                Theme.qml, Colors.qml (палитра gruvbox)
├─ components/            общий хром попапов: Popup*, Separator, PopupManager
├─ bar/                   Bar.qml (раскладка), BarPopup.qml (хром попапа)
└─ plugins/
   ├─ wifi/               Wifi.qml + WifiPopup.qml + WifiService.qml
   ├─ mihomo/             Mihomo.qml + MihomoPopup.qml + MihomoService.qml
   └─ audio|battery|brightness|clock|language|media|workspaces/  по одному модулю
```

Импорты между папками — через `qs.<папка>` / `qs.<папка>.<вложенная>` от корня
конфига (имя `taskbar` не пишется), синглтоны — `pragma Singleton` + доступ по
имени типа после импорта папки.

## Установка

```sh
sudo pacman -S quickshell          # стабильный v0.3
# или
paru -S quickshell-git             # актуальный master
```

## Запуск

Quickshell находит именованный конфиг по `~/.config/quickshell/taskbar/shell.qml`
и авто-релоадит панель при изменении файлов внутри конфига:

```sh
qs -c taskbar
```

> quickshell теперь единственный бар: `packages/hypr/components/autostart.lua`
> запускает `qs -c taskbar` вместо `waybar` (waybar больше не стартует).

## Следование теме

Палитра живёт в синглтоне `config/Colors.qml` (внутри конфига `taskbar`).
Базовый `packages/quickshell/taskbar/config/Colors.qml` — это gruvbox;
активная тема перекрывает его через merge в `install.py`:

```
themes/<t>/quickshell/taskbar/config/Colors.qml   ->   ~/.config/quickshell/taskbar/config/Colors.qml
```

Так `install.py theme set <t>` перецепляет симлинк `Colors.qml` на нужную
тему. Помимо цветов `Colors.qml` несёт настройки, которые тема
переопределяет поверх waybar-модуля `hyprland/workspaces`
(`workspaces.jsonc`): `workspaceFormat` и иконки.

Quickshell следит только за уже загруженными файлами, поэтому перецепку
симлинка `Colors.qml` он сам не замечает. Чтобы запущенная панель всё же
перекрашивалась без рестарта, `shell.qml` следит за `~/.dotfiles/.theme`
и через 400ms (когда `install.py` уже долинковал файлы) делает
`Quickshell.reload(true)`.

## Соответствие waybar

| waybar модуль                     | quickshell файл          | замечания                                                   |
|-----------------------------------|--------------------------|-------------------------------------------------------------|
| `hyprland/workspaces`             | `plugins/workspaces/Workspaces.qml` | `{name}`/`{icon}`, all-outputs, disable-scroll, click=activate |
| `custom/separator`                | `components/Separator.qml` | `\|`, 8px margins, gray                                     |
| `custom/media_title` (MPD)        | `plugins/media/Media.qml` | `media.sh --listen`, max-length 60, left/right click        |
| `clock`                           | `plugins/clock/Clock.qml` | HH:MM, alt-формат по клику, 1s                              |
| `custom/brightness` (hyprsunset)  | `plugins/brightness/Brightness.qml` | poll 2s, клик-toggle, скролл ±5%                            |
| `pulseaudio` (Pipewire)           | `plugins/audio/Audio.qml` | muted U+EEE8 red, headphone U+F025, max-volume 150, клик mute |
| `network`                         | `plugins/wifi/Wifi.qml` + `plugins/wifi/WifiService.qml` + `scripts/wifi.sh` | wifi-иконка (svg) в шапке, "Disconnected", ethernet скрыт; попап: switch, info, DNS, сети, пароль, speedtest |
| `custom/vpn` (mihomo)             | `plugins/mihomo/Mihomo.qml` + `plugins/mihomo/MihomoPopup.qml` + `plugins/mihomo/MihomoService.qml` | щит + VPN, попап: вкладки providers/servers, current server, ADD/update/ping, шестерёнка (конфиг mihomo) и троеточие (файл провайдера) |
| `battery` (sysfs)                 | `plugins/battery/Battery.qml` + `scripts/battery.sh` | warning <=30, critical <=15, charging/plugged иконки     |
| `hyprland/language`               | `plugins/language/Language.qml` | "US"/"RU" по activelayout, margin-right 20                  |

Палитра и шрифт: `config/Colors.qml` (текущая тема) + `config/Theme.qml`
(`JetBrainsMono Nerd Font` 13px/800, метрики, глифы, интервалы).

## mihomo (провайдер / сервер)

Модуль в баре — щит (`iconMihomo`) + `VPN`; зелёный при запущенном
`mihomo.service`, иначе серый. Цвета — из конфига kitty темы (`color2` =
зелёный, `color8` = серый). Клик открывает попап в стиле rofi: квадратная
рамка 4px (без скруглений) — толщина и цвет (`border_size` / `active_border`
= `#282828`) из конфига Hyprland, фон — `background1` (kitty `background`),
разделители и вторичный текст `dim`, выбранное — `foreground0`.

```
plugins/mihomo/Mihomo.qml          бар-элемент + BarPopup (позиция, показ/скрытие)
plugins/mihomo/MihomoPopup.qml     содержимое попапа (рамка, вкладки, списки, трафик)
plugins/mihomo/MihomoService.qml   синглтон: состояние + вызовы scripts/mihomo.sh
components/PopupButton.qml         квадратная кнопка (глиф или подпись)
components/PopupSwitch.qml         квадратный свитч вкл/выкл (ползунок влево-вправо)
components/PopupInput.qml          квадратное текстовое поле (форма ADD)
components/PopupSeparator.qml      разделитель попапа (2px, dim)
scripts/mihomo.sh                  все REST-запросы к mihomo (JSON на выходе) + пути конфигов
```

Попап — две вкладки (интерфейс на английском): **PROVIDERS**
(proxy-providers, у каждого число серверов) и **SERVERS** (страны
выбранного провайдера). Вкладка `SERVERS` появляется только когда есть
хотя бы один провайдер. Выбор провайдера переключает на его серверы.
Заголовок: щит, «MIHOMO», статус подключения
(`connected`/`disconnected`) и справа шестерёнка + свитч вкл/выкл. На
вкладке `SERVERS` сверху закреплён текущий выбранный сервер
(«CURRENT SERVER»); список ниже прокручивается (`Theme.visibleRows`) и
показывает пинг с маркером выбранного; подвал — live-трафик ↓/↑ и суммы
сессии (строки подписаны `SPEED:` и `TRAFFIC:`, значения по общему краю).

Кнопка **ADD** + **UPDATE** на вкладке `PROVIDERS`: **ADD** открывает форму
«PROVIDER NAME» + «SUBSCRIPTION URL» (фокус сразу в поле, Enter из имени
переходит в URL, Enter в URL или **SAVE** отправляет, Escape или **CANCEL**
закрывает; при ошибке под формой красная строка). Добавление скачивает
подписку (`scripts/mihomo.sh --add-provider`), сохраняет её в
`~/.config/mihomo/providers/<name>.yaml`, прописывает в `config.yaml`
(proxy-providers + `use:` в группе) и перезагружает mihomo; при сбое конфиг
откатывается из бэкапа. **UPDATE** перекачивает все
proxy-provider'ы по их URL и перечитывает состояние; кнопка **PING**
(healthcheck) только на вкладке `SERVERS`. Обе показывают спиннер, затем
на ~2.5 с — галочку (успех) или крестик (ошибка), и только после этого
возвращаются к подписи. При ошибке обновления `scripts/mihomo.sh --update`
пишет лог в `~/.config/mihomo/update.log`.

- **Шестерёнка** в шапке — открыть конфиг mihomo
  (`~/.config/mihomo/config.yaml`) в `kitty -e nvim`.
- **Троеточие** рядом с провайдером — открыть файл этого провайдера
  (`~/.config/mihomo/providers/<name>.yaml`; путь резолвит
  `scripts/mihomo.sh --path <provider>` с учётом `path:` из конфига).

- **Провайдер** — это proxy-provider (подписка), второй уровень — его
  серверы (страны).
- **Скорость** — и live-трафик (`/traffic`, запускается только пока
  попап открыт), и пинг. Пинг у «CURRENT SERVER» берётся из `--status`
  (поле `delay` — последний замер активного узла); кнопка PING делает
  healthcheck провайдера (`/providers/proxies/<p>/healthcheck`,
  блокирует ~5с), затем перечитываем узлы.
- **REST** — `http://127.0.0.1:9090` без секрета; группа определяется из
  `Theme.mihomoGroup` ("Proxies"), иначе берётся первый не-GLOBAL
  Selector/URLTest/Fallback/LoadBalance.

Попап — `PopupWindow` поверх панели, обёрнутый в `BarPopup` (общий хром:
якорь, регистрация в `PopupManager`, focus-grab, `closedAt`; см.
`PLUGIN_STYLE.md`). Панель — layer-shell поверхность, поэтому клик-снаружи
закрывает через `HyprlandFocusGrab` (`hyprland_focus_grab_v1`), а
`grabFocus: true` нужен, чтобы текстовые поля внутри попапа получали
клавиатуру. Позиция считается в `onAnchoring` через `mapToItem` (не
реактивно; ширина подписи досчитывается асинхронно из-за emoji-фолбэков,
поэтому якорь ещё обновляется по `onImplicitWidthChanged`).

## Отличия от waybar

- **Тема** — палитра вынесена в `config/Colors.qml`, который перекрывается
  темой (`themes/<t>/quickshell/taskbar/config/Colors.qml`), как `colors.css`
  у waybar. Бар следует за `install.py theme set` без ручного рестарта.
- **Звук** — Pipewire (`Pipewire.defaultAudioSink`) вместо pulseaudio;
  активный порт (наушники) определяется через `sink_port.sh` (`pactl`),
  потому что сервис Pipewire в Quickshell его не отдаёт напрямую.
- **Сеть** — маленький `wifi.sh` на `nmcli` вместо встроенного модуля
  (та же семантика текста в баре: wifi-иконка + ESSID или "Disconnected",
  ethernet скрыт); попап `WifiPopup.qml` добавляет info/DNS/сети/пароль/
  QR/speedtest, состояние живёт в `WifiService.qml`.
- **Батарея** — `battery.sh` повторяет sysfs-логику waybar (capacity из
  charge/energy_now, "Plugged" при онлайн-адаптере, "Full" при 100%);
  выводит JSON `{"text","class"}`, класс выбирает цвет
  (charging/critical/warning/иначе foreground0).
- **Язык** — раскладка инициализируется из `hyprctl devices -j` и
  обновляется по событию `activelayout`; полное имя xkb ("English (US)",
  "Russian") мапится в `format-en`/`format-ru`, как в
  `waybar/src/modules/hyprland/language.cpp` (short_description).
- Скрипты media/brightness/wifi/battery/sink_port/mihomo
  продублированы: пакет самодостаточен
  (`~/.config/quickshell/taskbar/scripts/`).
- Тултипов нет нигде (в waybar у всех модулей `tooltip: false`).
