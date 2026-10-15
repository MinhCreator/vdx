# Taskbar — инструкция для агента

Quickshell-бар (`qs -c taskbar`). Здесь правила, по которым написаны все
плагины: новый должен выглядеть и вести себя так, будто был здесь всегда.
Описание каждого плагина — `plugins/<name>/README.md`.

## Устройство

```
taskbar/
├─ shell.qml          бары по мониторам, окно Shell Manager, обои, захват экрана; перекраска при смене темы
├─ bar/               Bar.qml (зоны), BarLayout (реестр плагинов, раскладка), BarPopup (обвязка попапа)
├─ kit/               UI-компоненты (каталог ниже) и icons/ — SVG-иконки (+ icons/solid)
├─ components/        ThemeText, Separator, PopupManager, PopupCatcher (клик мимо попапа)
├─ config/            Theme (всё общее), Colors (палитра темы), ShellSettings (опции оболочки), PluginSettings (опции плагинов)
├─ apps/shellmanager/ окно настроек: Appearance (тема, обои, шрифт, курсор), Bar (мониторы, раскладка, модули), Plugins
├─ apps/capture/      захват экрана (Super+Shift+S): область / окно / экран, скриншот или запись
├─ scripts/           бэкенды: *.sh / *.py, на выходе только JSON (или строки, см. шапку)
└─ plugins/<name>/    <Name>.qml + <Name>Popup.qml + <Name>Service.qml (+ view-файлы, *.json)
```

Импорты — `import qs.<папка>` от корня конфига (`qs.config`, `qs.kit`,
`qs.bar`, `qs.plugins.wifi`, `qs.apps.shellmanager`, `qs.apps.capture`).
Синглтоны — `pragma Singleton` + `Singleton {}`.

## Три слоя плагина

1. **Скрипт** `scripts/<name>.sh` — единственное место, которое говорит с
   системой (nmcli, pactl, sysfs, REST). Каждая команда печатает один JSON; в
   шапке скрипта перечислены команды и формат ответа. Ошибки —
   `{"ok":false,"error":"..."}`. Скрипт самодостаточен. Если данные есть в
   сервисе Quickshell (Pipewire, Hyprland), скрипт не нужен.
2. **Сервис** `<Name>Service.qml` (синглтон) — состояние и действия, владеет
   всеми `Process` и `Timer`, отдаёт сырые данные (форматирует view):
   - свойства сгруппированы секциями `// ---- name ----`;
   - `popupShown()` / `popupHidden()` — что работает только при открытом попапе;
   - `run(proc, args)` — один хелпер запуска, `parse(text)` — один JSON-парсер;
   - действия: `busy` / `status` ("" | ok | error), сброс по
     `Theme.popupStatusMs`; текст ошибки — `error`, показывается в попапе.
3. **Бар-модуль** `<Name>.qml` — лицо в баре (`KitBarItem`), `MouseArea`
   (клик → `popup.toggle()`, колесо — быстрое действие), `BarPopup`, который
   форвардит `onShown` / `onHidden` в сервис, и `function openPopup() {
   popup.toggle(); }` — ей модуль открывается из папки (`plugins/folder`).
   **Попап** `<Name>Popup.qml` — корень `KitFrame`, только чтение сервиса и
   вызов его функций.

```qml
Item {
  id: root
  required property PanelWindow bar

  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  KitBarItem { id: label; icon: "wifi"; text: XService.value; tint: Theme.foreground0 }

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

Регистрация — запись в `bar/BarLayout.qml` (`plugins`: id, label, зона,
`icon` — имя SVG из `kit/icons`, `about`) и `Component { id: x; X { bar: root } }`
в `bar/Bar.qml`. Порядок, зоны и включённость пользователь меняет в Shell
Manager; выключить можно любой, Shell Manager всегда открывается по Super+S.
Переименовал id — добавь старое имя в `BarLayout.renamed`, сохранённые
раскладки мигрируют сами.

Общий бэкенд двух плагинов (music и radio — один MPD) — отдельная папка-сервис
(`plugins/mpd/`), каждый плагин держит в своём сервисе только своё.

## UI-правила (стиль kit)

Минимализм с уклоном в терминал: моно-шрифт, острые углы, почти монохром.
Эталон — попап Wi-Fi.

**Попап сверху вниз:** `KitHeader` → `KitLine` → группы, между ними `KitLine`
→ (футер с `KitButton`). Корень — `KitFrame` (рамка 2px цвета `frame`,
отступ 16, столбец с `spacing: 14`). Подложек под секции нет — группы
разделяют линии и воздух.

**Шапка** `KitHeader`: SVG-иконка (`icon`, `iconColor`), жирный заголовок
обычным регистром (`Wi-Fi`, `Mihomo`, `Battery`), под ним подзаголовок
мелким капсом через ` · ` (`CONNECTED · RULE`). Справа (дочерние): `KitBadge`
(статус-метка без рамки: квадратик + капс), `KitButton`, `KitSwitch`. Тумблер
в шапке включает то, что названо в заголовке.

**Группа:** подпись `KitLabel` (мелкий капс, `muted`, значение справа) →
содержимое. Строки настроек — `KitRow` / `KitSelect`: подпись и серая
подсказка слева, контрол справа. Пары «подпись — значение» — `KitInfo`.
Уровни — `KitBar` (3px, цвет по смыслу); ползунки — `KitSliderRow`.

**Выбор:** выбранное — заливка `background3` + жирный текст (+ галочка в
списках), не цвет. Ряд вариантов / вкладки — `KitChoices` (кнопки с иконками).
Несколько `KitSelect` в группе — открыт максимум один. Если открытый список не
должен ничего сдвигать — `KitSelect { overlay: true }`.

**Текст:** `KitText` (SemiBold), заголовки и выбранное — ExtraBold. Пустые
состояния — короткая фраза `muted` («Nothing is playing.»). Ошибки — красный
`KitText` внизу попапа.

**Цвет — только смысл:** `green` ок/вкл/зарядка, `red` ошибка/mute, `yellow` /
`orange` — внимание / особый режим (ночной свет), `muted` — нет данных. Качество
(пинг, сигнал, здоровье) — `Theme.qualityColor()` / `Theme.pingColor()`.

**Бар:** `KitBarItem` — иконка + короткий текст одного цвета. Ширина не должна
прыгать: вместо пропавшего значения — `--`. Иконки — solid или контур по
опции `ShellSettings.solidIcons`.

**Попап:** ширина `Theme.popupWidth`; позиция выбирается сама и не следует за
модулем, пока попап открыт; под модулем с открытым попапом — полоска 2px
цвета его `KitBarItem.tint` по нижнему краю бара (рисует `BarPopup`,
анимация — `ShellSettings.underlineAnimation`); Escape закрывает (плагин с вложенными экранами —
Wi-Fi — решает сам: назад или закрыть). Попап без xdg-grab (`grabFocus:
false`): фокус клавиатуры даёт `HyprlandFocusGrab`, клик мимо ловит
`PopupCatcher` — бар он не накрывает, поэтому клик по другому модулю сразу
открывает его попап. Захват экрана прячет попап (`PopupManager.frozen`), пока
его заменяет неподвижный кадр.

**Рефакторинг не меняет внешний вид** без согласования; новый вид — сначала
прототип одного попапа и скриншот, потом раскатка.

## Цвета и темы

`Colors.qml` — палитра активной темы (`themes/<t>/quickshell/.../Colors.qml`
перекрывает базу), `Theme` пробрасывает роли: `background0..3`,
`foreground0..2`, `gray` (рамки контролов), `frame` (рамка попапа), `muted`,
`dim`, акценты. Роли и правила палитры — `~/.dotfiles/themes/gruvbox/README.md`.
Новая тема — палитра в `themes/mktheme.py` и запуск; Shell Manager увидит её
сам (`scripts/themes.sh`). Хардкод цветов в QML запрещён — только `Theme.*`.

## Иконки

SVG в `kit/icons/<name>.svg`, 24×24, белые контуры в стиле Lucide со
`stroke-linecap="square"` / `stroke-linejoin="miter"`; `kit/icons/solid/` —
залитые варианты для бара (список имён — `KitIcon.solidNames`). `KitIcon`
перекрашивает их в любой цвет (`MultiEffect`). Глифы шрифта не используются.

## Состояние и настройки

- Опции пользователя — `ShellSettings` (`settings.json` в state-папке):
  новая опция = свойство в `JsonAdapter` + readonly-алиас + контрол на
  странице Shell Manager.
- Опции плагина — страница `<Name>Settings.qml` в папке плагина (поле
  `settings` в реестре `BarLayout`, Shell Manager › Plugins) из `KitToggleRow` /
  `KitOptionRow`; значения — `PluginSettings.get("<plugin>", "<key>", default)`
  (`plugins.json` в state-папке). Значение по умолчанию живёт в плагине.
- Пользовательские списки плагина (пресеты, провайдеры DNS) — `*.json` в
  папке плагина через `FileView` + `JsonAdapter` с `watchChanges`.
- Состояние плагина между перезапусками — `FileView { path:
  Quickshell.statePath("<name>.json") }` + `writeAdapter()` по `onAdapterUpdated`.
- Нужен root для sysfs — правило tmpfiles в `~/.dotfiles/system/etc/tmpfiles.d/`,
  ставится `./install.py system install`.

## Порядок работы

1. Скрипт → проверить каждую команду в терминале.
2. Сервис → бар-модуль → попап → строка в `Bar.qml` и `BarLayout`.
3. **Новый файл** не виден, пока нет ссылки: `./install.py link`, затем
   перезапуск. Правки существующих файлов подхватываются на лету (кроме
   функций `IpcHandler` — для них тоже перезапуск).
4. **Перезапуск:** `kill <pid>` (pid из `qs list --all`), убедиться, что
   инстансов 0, `setsid qs -c taskbar -d`, проверить, что инстанс ровно один.
   `qs kill` роняет бар, он сам поднимается с неработающим IPC.
5. **Проверка:** `qs log -c taskbar | grep -E 'ERROR|WARN'`; попап открывается
   `qs -c taskbar ipc call <ipcTarget> toggle` (пауза ≥ 1 с между вызовами),
   окно настроек — `ipc call shell open <appearance|bar>`, захват —
   `ipc call capture <open|close|stop>`; скриншот — `grim -g "X,Y WxH"`
   (логические координаты).
6. Обновить `plugins/<name>/README.md` и этот файл, если появилось правило
   или компонент.

## Подводные камни QML

- JS-движок QML старый: нет `Array.flatMap` (бросает TypeError, а в `try`
  пропадает молча) — `reduce` + `concat`.
- `console.log` в `qs log` не виден — для отладки `console.warn`.
- `sed -i` подменяет файл, и горячая перезагрузка его не замечает — правь
  на месте (Edit, `open(p, 'w')`) или перезапускай бар.
- Скриншот экрана в Hyprland — копия последнего кадра, программный курсор
  уже в нём (`overlay_cursor` не помогает). `cursor:invisible` применяется
  только на событии клавиатуры или по таймеру раз в 500 мс — результат
  надо проверять, а не ждать (см. `apps/capture/README.md`).

- Свойство `onSomething` — это обработчик сигнала; называй `checkedColor` и т.п.
- Не называть свойства/id `state`, `signal`, `status`, `padding` — конфликт со
  встроенными (`padding` у `Column`).
- `Column` / `Row` не раскладывают детей нулевого размера; в `Row` у детей нет
  `anchors.left/right`, в `Column` — `top/bottom`. Дети `Row`, которым нужны
  свои `MouseArea` / метки, — оборачивай корень в `Item` (см. `KitBarItem`).
- Свойства самого `Grid` (`columns`, `spacing`) в его же биндингах дают
  `NaN` — считай размер из родителя.
- Inline `component` в файле с собственным default-свойством даёт «is not a
  type» — выноси в отдельный файл.
- `Behavior` на readonly-свойстве нельзя — анимируй то, что пишется
  (`width`, `x`).
- `Process` с `running: true` стартует сразу; повтор — только если
  `!proc.running`. Колесо на layer-shell доходит только до `MouseArea`.
- Пользователь видит изменения сразу — ломать конфиг даже временно нельзя.

## Каталог kit (`kit/`)

| Компонент | Для чего |
|---|---|
| `KitFrame` | Корень попапа: фон, рамка `frame`, столбец |
| `KitHeader` | Иконка, заголовок, подзаголовок, действия справа |
| `KitLine` | Линия между группами |
| `KitLabel` | Подпись группы мелким капсом + значение справа |
| `KitText` | Текст в шрифте темы (SemiBold) |
| `KitIcon` | SVG из `kit/icons`, перекрашенный в `tint`; `solid` |
| `KitBarItem` | Лицо бар-модуля: иконка + текст |
| `KitBadge` | Статус-метка в шапке: квадратик + капс, без рамки |
| `KitButton` | Контурная кнопка: `icon`, `text`, `selected`, `busy`, `disabled`, `iconTint` |
| `KitChoices` | Ряд кнопок-вариантов / вкладок: `model [{label, value, icon?}]`, `current`, `stretch` |
| `KitSwitch` | Прямоугольный тумблер с квадратной ручкой |
| `KitRow` | Строка настройки: подпись + подсказка слева, контрол справа |
| `KitSelect` | То же с полем выбора; список под строкой или поверх (`overlay`) |
| `KitInfo` | «Подпись — значение» |
| `KitToggleRow` / `KitOptionRow` | Строка настроек плагина: тумблер / варианты, привязаны к `PluginSettings` |
| `KitBar` | Тонкий уровень 0..1 |
| `KitSlider` / `KitSliderRow` | Ползунок / ползунок с подписью или иконкой и значением |
| `KitInput` | Поле ввода с `❯` и блочным курсором |
| `KitSpinner` | Braille-спиннер |

`components/`: `ThemeText` (текст бара), `Separator` (`|` между модулями),
`PopupManager` (открыт только один попап).
