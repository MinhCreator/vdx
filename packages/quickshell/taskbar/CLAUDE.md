# Taskbar — инструкция для агента

Quickshell-бар (`qs -c taskbar`). Этот файл — правила, по которым написаны все
плагины. Новый плагин должен выглядеть и вести себя так, будто он был здесь
всегда. Описание каждого плагина — в `plugins/<name>/README.md`.

## Устройство

```
taskbar/
├─ shell.qml        бар на каждый экран + перезагрузка при смене темы
├─ bar/             Bar.qml (раскладка модулей), BarPopup.qml (обвязка попапа)
├─ components/      общие компоненты (каталог ниже)
├─ config/          Theme.qml (всё общее), Colors.qml (палитра, перекрывается темой)
├─ scripts/         бэкенды плагинов: *.sh, на выходе только JSON
└─ plugins/<name>/  <Name>.qml + <Name>Popup.qml + <Name>Service.qml (+ view-файлы, *.json)
~/.dotfiles/system/ файлы для /etc (tmpfiles и т.п.): ./install.py system install
```

Импорты — `import qs.<папка>` от корня конфига (`qs.config`, `qs.components`,
`qs.bar`, `qs.plugins.wifi`). Синглтоны — `pragma Singleton` + `Singleton {}`.

## Три слоя плагина

1. **Скрипт** `scripts/<name>.sh` — единственное место, которое говорит с
   системой (nmcli, pactl, sysfs, REST). Каждая команда печатает один JSON.
   В шапке скрипта перечислены все команды и формат ответа. Ошибки —
   `{"ok":false,"error":"..."}` (хелпер `error()`), неизвестная команда — тоже
   JSON-ошибка. Скрипт самодостаточен, общих bash-библиотек нет. Если данные есть в Quickshell-сервисе
   (Pipewire, Hyprland), скрипт не нужен.
2. **Сервис** `<Name>Service.qml` (синглтон) — состояние и действия. Владеет
   всеми `Process` и `Timer`. Отдаёт сырые данные, форматирование — во view.
   Шаблон:
   - свойства сгруппированы секциями `// ---- name ----`;
   - `popupShown()` / `popupHidden()` — что запускать только при открытом попапе;
   - `run(proc, args)` — один хелпер запуска скрипта, `parse(text)` — один JSON-парсер;
   - действия: `busy`/`status` ("" | ok | error) и сброс статуса таймером
     `Theme.popupStatusMs`; текст ошибки — в `error`, показывается в попапе.
3. **Бар-модуль** `<Name>.qml` — подпись (`ThemeText`), `MouseArea`
   (клик → `popup.toggle()`, колесо — быстрое действие) и `BarPopup`, который
   форвардит `onShown`/`onHidden` в сервис. **Попап** `<Name>Popup.qml` —
   корень `PopupFrame`, только чтение сервиса и вызов его функций.

Шаблон бар-модуля:

```qml
Item {
  id: root
  required property PanelWindow bar

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  ThemeText { id: label; text: Theme.iconX + " " + XService.value }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.toggle()
  }

  BarPopup {
    id: popup
    anchorItem: root
    ipcTarget: "x"
    bar: root.bar
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight
    onShown: XService.popupShown()

    XPopup { id: content; anchors.fill: parent }
  }
}
```

Регистрация — строка в `bar/Bar.qml` (`X { bar: root }`).

Если два плагина работают с одним бэкендом (music и radio — один MPD), общее
состояние и команды выносятся в отдельный сервис-папку (`plugins/mpd/`), а
каждый плагин держит в своём сервисе только своё (`MusicService`,
`RadioService`). Неактивный плагин в баре — серые иконка + имя (`♫ Music`).

## UI/UX правила

**Попап сверху вниз:** шапка → `PopupSeparator` → секции, разделённые
`PopupSeparator`. Корень — `PopupFrame` (рамка, отступы, столбец с
`spacing: Theme.popupPadding`).

**Шапка** — компонент `PopupHeader` (`glyph`, `title`, `subtitle`,
`subtitleColor`, кнопки/тумблер — дочерние элементы справа): иконка, заголовок
капсом (`WI-FI`, `MIHOMO`, `AUDIO`, `DISPLAY`, `BATTERY`, `MUSIC`, `RADIO`), под ним подзаголовок
состояния (`Theme.fontSize - 3`): зелёный — активно/подключено, `muted` —
выключено, `foreground2` — нейтральная информация. Справа — кнопки-глифы
(`headerButtonSize`, `frameless`, `hoverBackground: false`) и `PopupSwitch`.

**Тумблер в шапке** включает/выключает то, что названо в заголовке (радио
Wi-Fi, сервис mihomo, весь звук, воспроизведение лайков, радио). Если «выключить заголовок» нельзя (DISPLAY),
тумблера нет, а переключатель живёт в своей секции (`PopupSectionTitle` +
`PopupSwitch`). Исключение, согласованное с пользователем: энергосбережение
в шапке BATTERY (иконка становится листочком). Тумблеры — обычные зелёные.

**Списки и выбор:**
- выбор одного значения из списка — `PopupSelect` (заголовок `LABEL: VALUE`);
- свой дропдаун (сложные пункты) — `PopupDropdown` + `PopupDropdownItem`;
- несколько дропдаунов в группе — `Column { spacing: 4 }`, открыт максимум один
  (`collapseOthers(open)` в попапе);
- выбранный пункт везде отмечается **белой полосой слева + зелёной галочкой
  справа**; невыбранный текст — `foreground2`, при наведении — фон `background2`;
- ряд из 2–4 вариантов, видимых сразу — `PopupChoices`.

**Значения:** пары «подпись — значение» — `PopupInfoList` (две колонки
`Row { spacing: 16 }` для широких попапов). Ползунки — `PopupSliderRow`: с
`label` (подпись + значение сверху, ползунок во всю ширину) или с
`glyph`/`clickable` (иконка-кнопка, ползунок, значение в строку — громкость).

**Типографика:** весь текст — `ThemeText`. Подписи и заголовки секций — КАПС,
`letterSpacing: 1`. Подписи у значений — `Theme.fontSize - 2`, `dim`. Значения —
`Theme.fontSize - 1`. Ошибки — `PopupError { text: XService.error }` внизу
попапа.
Пустые состояния — muted-текст (`WI-FI IS OFF`, `NO PROVIDERS`), не пустота.

**Цвета смысла:** `green` — ок/активно/зарядка, `red` — ошибка/mute/критично,
`yellow` — предупреждение, `orange` — особый режим (ночной свет, требуется
перезагрузка), `aqua` — энергосбережение, `muted` — нет данных/выключено.
Качество (пинг, сигнал, здоровье) — `Theme.qualityColor()` / `Theme.pingColor()`.

**Ширина попапа:** `Theme.popupWidth` (370) — если есть инфо в две колонки,
иначе `Theme.popupWidthCompact` (300).

**Позиция попапа:** по умолчанию растёт влево от правого края плашки. Для
плашек слева с изменяемой шириной — `alignLeft: true` у `BarPopup`, иначе попап
прыгает.

**Вкладки** (несколько режимов в одном попапе) — `PopupChoices` под шапкой,
активная вкладка — свойство `view` в сервисе, при открытии выбирается по
текущему состоянию.

**Бар:** `иконка + один пробел + значение`. Подпись не должна менять ширину при
смене состояния (попап прыгает): заменяй текст на `--` той же длины, красить —
можно, менять иконку — только на глиф той же ширины.

**Минимализм:** без скруглений, теней, тултипов. Новое — только если решает
задачу. При рефакторинге внешний вид не меняется без согласования.

## Иконки

Только Material Design из JetBrainsMono Nerd Font, только через `Theme.icon*`
(суррогатные пары `"\udbXX\udcXX"`, в комментарии `// nf-md-<name>`). Ширина
глифов разная (большинство 9.8px при 13px, `brightness_4..7` — 12.8px), поэтому
глифы, которые сменяют друг друга на месте, меряй (см. «Проверка»).

## Состояние и настройки

- Пользовательские настройки (списки, пресеты, расписания) — `*.json` в папке
  плагина, читаются `FileView` + `JsonAdapter` с `watchChanges`. Ничего не
  хардкодить в коде, что пользователь может захотеть поправить
  (`dns_providers.json`, `night_light.json`).
- Состояние, переживающее перезапуск — `FileView { path:
  Quickshell.statePath("<name>.json") }` + `JsonAdapter`, запись
  `writeAdapter()` по `onAdapterUpdated` (с задержкой, если пишется часто).
- Нужен root для sysfs — правило tmpfiles в `~/.dotfiles/system/etc/tmpfiles.d/`
  (группа `wheel`); пользователь ставит его `./install.py system install`.

## Порядок работы

1. Скрипт → проверить каждую команду в терминале (`bash scripts/x.sh --cmd`).
2. Сервис → бар-модуль → попап → строка в `Bar.qml`.
3. **Новые файлы** не видны Quickshell, пока не созданы симлинки:
   `cd ~/.dotfiles && python3 install.py link`, затем перезапуск
   `pkill -x qs; setsid qs -c taskbar -d`. Удалённые — `install.py cleanup`.
   Правки существующих файлов подхватываются на лету.
4. Проверка: `qs log -c taskbar | grep -iE 'warn|error|caused'`; бар —
   скриншот `grim -g "X,Y WxH"`. Любой попап открывается сам:
   `qs -c taskbar ipc call <ipcTarget> toggle` (свойство `BarPopup.ipcTarget`,
   у всех плагинов — имя папки), затем `grim` и тот же вызов, чтобы закрыть.
   Между вызовами — пауза ≥ 1 с (защита от повторного открытия).
   После перезапуска `qs` IPC не откроет попап, пока пользователь хоть раз не
   кликнул по бару (Wayland не даёт grab без ввода: «Failed to create grabbing
   popup»). Тогда — попросить кликнуть или открыть попап самому.
5. Обновить `plugins/<name>/README.md` и этот файл, если появилось новое правило
   или компонент.

## Подводные камни QML

- Свойство с именем `onSomething` — это обработчик сигнала (`onColor:` не
  присвоить); называй `checkedColor` и т.п.
- Не называть свойства/id `state`, `signal`, `status` у Item — конфликт со
  встроенными.
- `this` в обработчиках ненадёжен — передавай `id`.
- В `Row` у детей нельзя `anchors.left/right`; в `Column` — `top/bottom`.
- `Process` с `running: true` в декларации стартует сразу; повторный запуск —
  `proc.running = true` только если `!proc.running`.
- Колесо на layer-shell доходит только до `MouseArea`, не до `WheelHandler`.
- Пользователь видит изменения сразу (горячая перезагрузка) — ломать конфиг
  даже временно нельзя.

## Каталог компонентов (`components/`)

| Компонент | Для чего |
|---|---|
| `ThemeText` | Любой текст в шрифте темы |
| `PopupFrame` | Корень попапа: рамка + столбец |
| `PopupHeader` | Шапка: иконка, заголовок, подзаголовок, действия справа |
| `PopupError` | Красная строка ошибки, скрыта при пустом тексте |
| `PopupSeparator` | Разделитель секций |
| `PopupSectionTitle` | Заголовок секции + слот справа (тумблер, пометка) |
| `PopupButton` | Кнопка: `label` или `glyph`; `busy`, `status`, `active`, `frameless` |
| `PopupSwitch` | Тумблер (`checkedColor` / `uncheckedColor`) |
| `PopupInput` | Поле ввода с подписью (`echoMode`) |
| `PopupInfoRow` / `PopupInfoList` | «ПОДПИСЬ … значение» / столбец таких из модели `{label, value, color?}` |
| `PopupDropdown` | Раскрывающийся список: `title`, `busy`, `status`, `disabled`, прокрутка |
| `PopupDropdownItem` | Пункт: `label`, `active`, слот `trailing` |
| `PopupSelect` | Выбор одного значения: `label`, `model [{label, value}]`, `current`, `picked(value)` |
| `PopupChoices` | Ряд кнопок-вариантов той же моделью |
| `PopupMeter` | Уровень только для чтения: подпись, значение, полоска, заметка (лимиты) |
| `PopupSlider` / `PopupSliderRow` | Ползунок 0..1 / ползунок с подписью или иконкой и значением |
| `PopupSpinner` | Индикатор загрузки |
| `PopupManager` | Синглтон: открыт только один попап |
| `Separator` | `|` между модулями бара |
