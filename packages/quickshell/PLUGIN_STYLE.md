# Стиль плагинов quickshell (модуль бара + попап)

Правила, по которым сделаны плагины **Mihomo** и **Wi-Fi**
(`<Name>.qml` + `<Name>Popup.qml` + `<Name>Service.qml`). Новый плагин,
собранный по этим правилам, визуально неотличим от существующих: та же сетка,
та же палитра, те же компоненты.

Эталон: `Mihomo*`. Переиспользуемый «хром»: `BarPopup.qml`,
`PopupButton.qml`, `PopupSwitch.qml`, `PopupSpinner.qml`, `PopupInput.qml`,
`PopupSeparator.qml`. Общее состояние попапов: `PopupManager.qml`.

---

## 0. Инварианты (нарушать нельзя)

- **Радиус = 0 везде.** Ни одного `radius`. Стиль — rofi, квадратная рамка.
- **Только `Theme.*`** для цвета, шрифта, метрики и глифов. В QML нет
  hex-цветов, кроме литерала `"transparent"`.
- **Один шрифт:** `Theme.fontFamily` (`JetBrainsMono Nerd Font`),
  `Theme.fontSize` (13), `Theme.fontWeight` (`Font.ExtraBold`). Иконки — Nerd
  Font глифы из `Theme` (`icon*`).
- **Никаких тултипов, теней, градиентов, размытия.**
- **Анимаций ровно две:** ползунок свитча (`120ms`, `Easing.OutCubic`) и
  вращение спиннера (`800ms`, `Infinite`). Всё остальное статично.
- **Регистр.** Три разных категории:
  - «ярлыки» (заголовок, вкладки, подписи кнопок, подписи футера) — ВЕРХНИЙ
    + `font.letterSpacing: 1`;
  - «статусы» — строчными: состояния связи в шапке (`connected`,
    `disconnected`, `connecting`, `off`), короткие ошибки в шапке;
  - «пустые состояния» (подсказки вроде «Wi-Fi is off», «No providers») —
    **Sentence case**: первая буква заглавная, остальное строчными. Точки в
    конце не ставим. Если пустое состояние стоит **внутри секции со своим
    заголовком**, оно набирается как под-ярлык: ВЕРХНИЙ + `letterSpacing: 1`,
    `fontSize - 2`, `muted`, слева (в списках сети Wi-Fi: `NO KNOWN NETWORKS
    FOUND`, `NO OTHER NETWORKS FOUND`).
- **Рамки контролов читаемы.** У кнопок, свитчей и текстовых полей рамка в
  покое — `muted` (не `frame`): `frame` (#282828) сливается с фоном попапа
  (`background1`), контрол перестаёт угадываться. `frame` остаётся только у
  внешней рамки попапа.
- **Один попап на бар.** Одновременно открыт максимум один попап; открытие
  нового закрывает предыдущий. Обеспечивает `PopupManager`.
- **Никакого `PopupWindow` в модулях напрямую.** Модуль использует `BarPopup`,
  который делает якорь, регистрацию, focus-grab и `closedAt`.

---

## 1. Состав плагина

Один плагин — до пяти файлов в `packages/quickshell/`:

| Файл | Роль |
|------|------|
| `<Name>.qml` | Модуль бара: `Item` + подпись + `MouseArea` + `BarPopup` + `<Name>Popup` внутри. |
| `<Name>Popup.qml` | Содержимое попапа (рамка и вся вёрстка). Не знает про процессы. |
| `<Name>Service.qml` | Синглтон (`pragma Singleton`): состояние, действия, все `Process`/`Timer`. |
| `scripts/<name>.sh` | Слой данных: вся работа с системой, JSON в stdout. |
| — | Если нужен новый «хром» (кнопка/свитч/…), он добавляется отдельным `Popup*.qml` и переиспользуется всеми плагинами. |

Общие файлы (в `packages/quickshell/`, у всех плагинов одни и те же):
`BarPopup.qml`, `PopupManager.qml`, `PopupButton.qml`, `PopupSwitch.qml`,
`PopupSpinner.qml`, `PopupInput.qml`, `PopupSeparator.qml`.

Правила разделения:
- **Бар** и **попап** только рисуют `Service`. Никаких `Process`/`Timer` и
  системных вызовов в `<Name>.qml` / `<Name>Popup.qml`.
- **Service** — единственная точка ввода-вывода; бар и попап читают его
  свойства и зовут его функции.
- **Скрипт** печатает JSON в stdout; QML парсит через `StdioCollector`
  (для построчного потока — `SplitParser`, см. `--traffic`).
- Синглтоны (`Theme`, `Colors`, `PopupManager`, `MihomoService`, `WifiService`)
  Quickshell регистрирует автоматически по `pragma Singleton` + имя файла;
  `qmldir` писать не нужно. У простых синглтонов корень — `QtObject`
  (`Colors`, `Theme`, `PopupManager`); у сервисов с `Process`/`Timer` —
  `Singleton` (`Quickshell/Singleton`, наследует `ReloadPropagator`, поэтому
  релоад конфига доходит и до вложенных процессов). Оба корня валидны в
  Quickshell v0.3.
- Модуль добавляется в нужный `Row` в `Bar.qml`; глифы/метрики — в `Theme.qml`,
  палитра — в `Colors.qml` активной темы.

---

## 2. Дизайн-токены

### 2.1 Цвета (`Colors.qml` → `Theme.*`)

| Токен | Значение | Где использовать |
|-------|----------|------------------|
| `background0` | `#202020` | фон бара, поле ввода (`PopupInput`) |
| `background1` | `#32302f` | фон попапа (тело рамки) |
| `background2` | `#3c3836` | ховер строки, ховер кнопки |
| `foreground0` | `#d4be98` | основной текст, выбранное, акцентная полоса, подчёркивание активной вкладки, рамка поля с фокусом |
| `foreground1`/`foreground2` | `#ddc7a1`/`#bdae93` | ховер поля ввода (промежуточное состояние) |
| `green` | `#a9b665` | «connected», пинг < 150 мс, свитч ON |
| `yellow` | `#d8a657` | пинг < 400 мс |
| `orange` | `#e78a4e` | пинг ≥ 400 мс |
| `red` | `#ea6962` | узел мёртв / ошибка действия |
| `muted` | `#928374` | «disconnected», выключенный свитч, пустые состояния, **рамки контролов в покое** |
| `frame` | `#282828` | **только внешняя рамка попапа** |
| `dim` | `#665c54` | вторичный текст, разделители, неактивная вкладка/иконки, подписи футера |

Правило выбора: **основное/активное → `foreground0`; второстепенное →
`dim`; выключенное/недоступное → `muted`; статус → акцентный цвет; рамки
контролов в покое → `muted`.**

### 2.2 Типографика

- База: `font.pixelSize: Theme.fontSize` (13), `font.weight: Theme.fontWeight`.
- Отклонения — только уменьшение:
  - `Theme.fontSize - 1` — значения пинга, счётчики, глифы кнопок;
  - `Theme.fontSize - 2` — подписи вкладок/кнопок;
  - `Theme.fontSize - 3` — статус в шапке, «CURRENT SERVER», лейбл `PopupInput`.
- `font.letterSpacing: 1` — у всех UPPERCASE-ярлыков.
- Регистр — по §0 (ярлыки / статусы / пустые состояния).
- Обрезка длинного текста — `elide: Text.ElideRight`.

### 2.3 Метрики (`Theme.qml`)

| Токен | Значение | Смысл |
|-------|----------|-------|
| `barHeight` | `34` | высота бара |
| `popupWidth` | `370` | ширина попапа |
| `popupFrameWidth` | `4` | толщина рамки |
| `popupPadding` | `10` | внутренние отступы |
| `popupGap` | `6` | зазор между баром и попапом |
| `rowHeight` | `26` | высота строки списка (общая для всех попапов) |
| `visibleRows` | `8` | видимых строк (высота списка = `26 × 8`) |
| `switchWidth` | `34` | ширина свитча |
| `switchKnob` | `14` | ползунок свитча |
| `popupInputHeight` | `24` | высота поля ввода (`PopupInput`) |

Локальные «магические» числа, повторяющиеся во всех плагинах (держитесь их):
`Column.spacing = Theme.popupPadding`; высота шапки и строки вкладок = `20`; разделитель = `2`;
шапка: отступы 6/8; вкладки: `spacing 4`, ширина вкладки =
`text.implicitWidth + 16`, подчёркивание активной = `2`;
пиннед-строка = `36` + зазор `6`; колонка значений справа = `52` (`rightMargin 4`,
`AlignRight`, `fontSize - 1`); акцентная полоса = `2`; иконка «dots» = `20`;
футер: `spacing 4`, строки `18`, общий левый край значений = `82`, зазор
вправо/вверх = `14`.

Общие функции форматирования — в `Theme`, а не в сервисах: `humanRate(bytes)`
(B/s … GB/s) и `humanSize(bytes)` (B … TB); их используют оба попапа (wifi и
mihomo).

---

## 3. Каркас попапа (сверху вниз)

```
Rectangle frame                     color background1, border 4px frame
└── Column col                      margins = 4+10, spacing = 10
    ├── header        (h 20)        иконка · 6 · ЗАГОЛОВОК · 8 · статус   |   справа: gear, switch
    ├── divider       (h 2, dim)
    ├── tab bar       (h 20)        слева вкладки-текст (spacing 4) · справа действия-кнопки (spacing 6)
    ├── content       (высота = 26×8 [+42])   список(ы) + пустые состояния
    ├── divider       (h 2, dim)
    └── footer        (spacing 4)   две строки по 18: SPEED и TRAFFIC
```

`implicitHeight` попапа = `frame.implicitHeight` =
`col.implicitHeight + 2 × (popupFrameWidth + popupPadding)`.

Все горизонтальные разделители (`divider`) — `PopupSeparator { width:
parent.width }` (2px, `dim`). Руками `Rectangle` для разделителя не рисуем.

### Шапка
- Слева: глиф-иконка (`fontSize`), `leftMargin 6` до UPPERCASE-заголовка
  (`fontSize`, `letterSpacing 1`), `leftMargin 8` до статуса
  (`fontSize - 3`, `green`/`muted`).
- Справа `Row` (spacing 6): `PopupButton` с глифом и `PopupSwitch`.

### Вкладки

Вкладки и кнопки выглядят **по-разному**: вкладка отвечает «где я», кнопка —
«сделай». Рамка есть только у кнопок. Вкладка — это **просто текст с
подчёркиванием активной**, без рамки и без заливки, во всех состояниях.

Каноничный код (копировать в `<Name>Popup.qml` как есть):

```qml
Row {
  anchors { left: parent.left; top: parent.top }
  height: parent.height
  spacing: 4

  Repeater {
    model: ["NETWORKS", "SAVED"]        // по одной строке на вкладку

    delegate: Item {
      id: tabItem
      required property string modelData
      required property int index
      readonly property bool active: root.tab === index

      // ширина = текст + 16 (по 8px паддинга с каждой стороны под клик)
      width: tabText.implicitWidth + 16
      height: parent.height

      Text {
        id: tabText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1     // оптическая центровка над полосой
        text: tabItem.modelData
        // активная — акцент; на ховере — тоже акцент (но без подчёркивания)
        color: tabItem.active || tabArea.containsMouse ? Theme.foreground0 : Theme.dim
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize - 2
        font.weight: Theme.fontWeight
        font.letterSpacing: 1
      }

      // активная: полоса 2px по низу вкладки, во всю ширину
      Rectangle {
        visible: tabItem.active
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 2
        color: Theme.foreground0
      }

      MouseArea {
        id: tabArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
          root.tab = tabItem.index;
          root.svc.closeView();              // смена вкладки закрывает оверлеи
        }
      }
    }
  }
}
```

Правила:
- Модель — обычный массив строк, по элементу на вкладку; индекс совпадает с
  `root.tab`.
- Свойство `active` вычисляется из `root.tab === index`; больше нигде состояние
  вкладки не хранится.
- Клик по вкладке **всегда** закрывает оверлей (`root.svc.closeView()` или
  аналог), чтобы список и форма не оказались на одной высоте.
- Активная вкладка помечена **только** полосой `2px` снизу; ховер меняет цвет
  текста, но не рисует рамку и не заливает вкладку.

### Действия вкладки

Справа от вкладок, в той же строке высотой `20`, живут действия текущей
вкладки:
- Один или несколько `PopupButton` в `Row { spacing: 6 }`.
- Каждая кнопка видна только для своей вкладки и только в режиме списка
  (`view === "list"`) — оверлеи несут свои кнопки.
- Если действие зависит от состояния (например, `DISCONNECT` — только при
  активном подключении), это видно в условии `visible`.
- Кнопки, привязанные к текущему соединению (disconnect, forget), показываются
  **только** при `connected` / `saved` — не мигают «вхолостую».

### Списки
- `ListView { clip: true; boundsBehavior: Flickable.StopAtBounds }`, фиксированная
  высота делегата (`Theme.rowHeight`).
- Делегат-строка: фон `background2` только на ховере и **не** у выбранной;
  выбранная — акцентная полоса `2px` слева цветом `foreground0`.
- **Read-only списки** (например, вкладка SAVED у Wi-Fi): строка не реагирует на
  клик и **не подсвечивается при наведении** — единственный интерактивный
  элемент — иконка действия справа (dots), и ховер живёт только на ней.
- Имя: слева, `leftMargin 8`, `elide`, цвет `foreground0` (выбранная) / `dim`.
- Число справа — фиксированная колонка `width 52`, `rightMargin 4`,
  `horizontalAlignment: Text.AlignRight`, `fontSize - 1`, чтобы значения
  не «дрожали».
- Пиннед «CURRENT …» (строка `36` + зазор `6`): подпись `dim`/`fontSize-3`/
  `letterSpacing 1` над значением `foreground0`; справа — тот же блок значений.
- Пустое состояние — по центру списка/панели, `muted`, `fontSize`, **Sentence
  case**: `Wi-Fi is off`, `Mihomo is off`, `No providers`, `No servers`. Точку
  в конце не ставим. Исключение — пустые **секции с заголовком** (списки сети
  Wi-Fi): под-ярлык слева, ВЕРХНИЙ + `letterSpacing: 1`, `fontSize - 2`,
  `muted` (`NO KNOWN NETWORKS FOUND`, `NO OTHER NETWORKS FOUND`).
  Текст виден **только** когда список реально пуст (`model.length === 0`) или
  когда действие недоступно (например, радио выключено), и скрыт, если открыт
  оверлей.

### Футер
- Две строки по `18`, `spacing 4`. Подписи `SPEED:`/`TRAFFIC:` — `dim`,
  `letterSpacing 1`; значения выровнены по общему левому краю `82`; первое
  значение (`↓`) — `foreground0`, второе (`↑`) — `dim`, зазор `14`.

---

## 4. Компоненты «хрома»

### `BarPopup`
Общий каркас попапа для всех модулей. Сам по себе — `PopupWindow`, но
инкапсулирует всё, что повторяется:

- Принимает `anchorItem` (модуль) и `bar` (PanelWindow из `Bar.qml`).
- Считает якорь в `anchor.onAnchoring` через `anchorItem.mapToItem(...)` —
  `x = mapToItem(...).x - 1`, `y = barHeight - 1`, `height = 1 + popupGap`.
- `color: "transparent"`, `implicitWidth: Theme.popupWidth`,
  `visible: false`, `grabFocus: true` (иначе `PopupInput` не получит клавиши).
- Регистрируется в `PopupManager`: при `visible → true` зовёт
  `PopupManager.open(root)`, при `false` — `PopupManager.close(root)`.
- Шлёт два сигнала: `shown()` / `hidden()` — модуль вешает туда всю свою
  специфику (счётчик `popupsOpen`, `refreshAll`, `resetView`).
  Имена именно такие: `opened`/`closed` уже объявлены у `PopupWindow`, и
  переопределять их нельзя (`qt.qml.invalidOverride`).
- Держит `HyprlandFocusGrab` (`active: root.visible`) и `closedAt`, которое
  модуль читает в `MouseArea`:
  ```qml
  onClicked: {
    if (Date.now() - popup.closedAt < 300) return;   // эхо close
    popup.visible = !popup.visible;
  }
  ```
- Модуль при смене ширины подписи зовёт `popup.anchor.updateAnchor()`
  (`onImplicitWidthChanged: if (popup.visible) popup.anchor.updateAnchor()`).

### `PopupManager`
Синглтон-`QtObject`, хранит `current: var`. Функции `open(win)` и `close(win)`.
`open` сначала переключает `current` на новый попап, потом гасит предыдущий
(`prev.visible = false`) — чтобы `close(prev)`, вызванный из
`onVisibleChanged` предыдущего, был no-op. Ничего кроме «какой попап открыт»
не знает.

### `PopupButton`
- `implicitHeight: 20`; ширина `label.implicitWidth + 14` для текста или `20`
  для глифа.
- Рамка `1px`: **в покое `muted`**, на ховере — цветом `tint`; заливка на
  ховере `background2`.
- Подпись — UPPERCASE, `fontSize - 2`, `letterSpacing 1`; глиф — `fontSize - 1`.
- `tint` (по умолчанию `dim`), `disabled`, `busy`, `status` (`""`/`ok`/`error`).
- `busy` → `PopupSpinner`; `status: "ok"` → `iconOk` (`green`), `"error"` →
  `iconError` (`red`).
- Ширина фиксируется по подписи (`label.implicitWidth + 14`), чтобы кнопка не
  «прыгала» при переходе в `busy`.
- `disabled` → `opacity 0.4` (но `busy` остаётся яркой, чтобы спиннер читался);
  клик срабатывает только если `!disabled && !busy`.

### `PopupSwitch`
- `implicitWidth: switchWidth (34)`, `height: 20`.
- Дорожка `transparent` с рамкой `1px`: **в покое `muted`**, на ховере —
  цветом состояния.
- Ползунок `switchKnob (14)`, `x: 2` / `width - knob - 2`, цвет `onColor`
  (`green`) / `offColor` (`muted`), `Behavior on x { 120ms OutCubic }`.
- `signals: toggled()`; `disabled` → `opacity 0.4`.

### `PopupSpinner`
- `Item 14×14`, глиф `Theme.iconSpinner`, `tint`, `fontSize - 1`.
- `RotationAnimator 0→360`, `800ms`, `Infinite`, `running: visible`.

### `PopupSeparator`
- Единственное место, где рисуется разделитель попапа: `Rectangle` высотой `2`,
  цвет `dim`.
- Использование — `PopupSeparator { width: parent.width }`; вручную `Rectangle`
  для разделителя не рисуем, иначе два разделителя разойдутся по высоте/цвету.

### `PopupInput`
- Высота `implicitHeight = labelText.implicitHeight + 4 + popupInputHeight`.
- Сверху лейбл UPPERCASE, `fontSize - 3`, `letterSpacing 1`, `dim`.
- Поле `height: popupInputHeight`, фон `background0`, рамка `1px`:
  **в покое `muted`**, на ховере `foreground1`, при фокусе `foreground0`.
- Внутри `TextInput` с `leftPadding/rightPadding 6`, `verticalAlignment:
  TextInput.AlignVCenter`; плейсхолдер (`dim`) виден только пока поле пустое и
  без фокуса.
- `property alias text` / `property alias input`, сигналы `textEdited` /
  `accepted`; владелец сам выставляет `input.echoMode` и зовёт
  `input.forceActiveFocus()` при показе оверлея.

Новый «хром» добавляйте рядом и с теми же принципами (квадрат, `Theme.*`,
ховер `background2`, рамка в покое `muted`, один сигнал действия).

---

## 5. Взаимодействие и поведение

**Модуль бара**
- `Item` с `implicitWidth/Height` от `Text`; подпись = `Service.barLabel()`.
- Цвет подписи по состоянию (`green` включено / `muted` выключено и т.п.).
- Внутри — `BarPopup { id: popup; anchorItem: root; bar: root.bar }`, внутри
  него — `<Name>Popup`. Больше ничего про окно модуль не знает.
- `MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }`,
  клик — через `popup.closedAt` (см. `BarPopup`).
- Если ширина подписи меняется асинхронно (эмодзи-фоллбэк, смена SSID),
  добавить `onImplicitWidthChanged: if (popup.visible) popup.anchor.updateAnchor()`.

**Один попап на бар**
- Открытие нового попапа автоматически закрывает предыдущий через
  `PopupManager.open(...)`. Модуль, который хочет закрыть свой попап, просто
  ставит `visible = false` — `BarPopup` сам отрегистрируется.
- Внешний клик закрывает `HyprlandFocusGrab` внутри `BarPopup` (`active: visible`,
  `onCleared` → `closedAt = now; visible = false`).
- `closedAt` гасит повторный клик в течение ~`300 мс` после закрытия
  (композитор шлёт `Cleared`, затем клик приходит в модуль).

**Прочее**
- Единственная анимация состояния — свитч и спиннер; переходы не добавляем.
- Оптимистичный UI: переключатель меняется сразу, реальное состояние
  подтягивается таймером «settle».
- Транзиентный результат действия (`ok`/`error`) показывается ~`2500 мс`, затем
  кнопка возвращается к подписи.
- Открытие редактора: сначала закрыть попап (`closeRequested`), потом
  `Quickshell.execDetached(["kitty", "-e", "nvim", путь])`.
- Живые потоки (трафик) идут только пока попап открыт (счётчик `popupsOpen`).

---

## 6. Семантика состояний

- `connected` → `green`; `disconnected` → `muted`.
- Пинг: `≤ 0` → `red` и текст `—`; `< 150` → `green`; `< 400` → `yellow`;
  иначе `orange`. Формат `«N ms»`, выравнивание вправо.
- Ховер строки — `background2`; выбранное — акцент `2px` + `foreground0`.
- Неактивная вкладка/иконка — `dim`; активная — `foreground0` (+ подчёркивание
  `2px` у вкладки).
- Пусто/недоступно — `muted`, **Sentence case** (`Wi-Fi is off`,
  `No providers`); пустое **внутри секции с заголовком** — под-ярлык капсом
  (`NO KNOWN NETWORKS FOUND`).
- Ошибка действия показывается рядом с кнопкой/в форме оверлея (например,
  `connectError`, `dnsError`, `addError`) и сбрасывается при старте нового
  действия, чтобы не перекрывать актуальный статус.

---

## 7. Do / Don't

**Do**
- Любой цвет/размер/глиф — через `Theme`.
- Квадраты и штрихи `1/2/4px`; разделители — `2px` `dim` (`PopupSeparator`).
- Вкладки — текст с подчёркиванием активной; рамка только у кнопок, свитчей и
  полей ввода (в покое — `muted`).
- Read-only списки (SAVED) — без подсветки строки, ховер только на иконке
  действия справа.
- UPPERCASE + `letterSpacing 1` для ярлыков; статусы — строчными; пустые
  состояния — Sentence case (`Wi-Fi is off`, `No providers`), а пустые
  **секции** — под-ярлыком капсом (`NO KNOWN NETWORKS FOUND`).
- Числа — в фиксированной колонке.
- `PointingHandCursor` и `hoverEnabled: true` на всём кликабельном.
- Держать состояние и ввод-вывод в `Service`, вёрстку — в `Popup`, окно — в
  `BarPopup`, «какой попап открыт» — в `PopupManager`.
- Англоязычные комментарии в коде, объясняющие «почему» и связь с waybar.

**Don't**
- `radius`, тени, градиенты, размытие, `DropShadow`.
- Хардкод цветов/шрифтов/размеров в QML (кроме `"transparent"`).
- Тултипы (`tooltip: false` — как в waybar).
- `Process`/`Timer`/системные вызовы внутри модуля или попапа.
- Анимации сверх свитча и спиннера.
- Свои кнопки/свитчи/поля вместо `PopupButton`/`PopupSwitch`/`PopupInput`/
  `PopupSpinner`.
- Свои разделители-`Rectangle` вместо `PopupSeparator`.
- Вкладки в рамке или с заливкой (их не отличить от кнопок).
- Рамки контролов цветом `frame` (сливаются с фоном попапа).
- **Свой `PopupWindow`/`HyprlandFocusGrab` в модуле** — только `BarPopup`.
- Пустые состояния без заглавной буквы (`no providers`, `wi-fi is off`).

---

## 8. Чеклист нового плагина

1. Добавить цвета (если реально новые) в `Colors.qml`, метрики/глифы — в
   `Theme.qml` (`iconX`, `xIntervalMs`, `rowHeight`, …).
2. Написать `scripts/<name>.sh`: JSON в stdout, вся системная работа здесь.
3. Написать `<Name>Service.qml` (`pragma Singleton`, корень — `Singleton`):
   состояние, действия, `Process`/`Timer`, `barLabel()`, `refresh*()`,
   `open*()`.
4. Написать `<Name>.qml`: `Item` + `Text` + `MouseArea` +
   `BarPopup { anchorItem: root; bar: root.bar }` c двумя хендлерами
   (`onShown` / `onHidden`) + `<Name>Popup` внутри.
5. Написать `<Name>Popup.qml`: рамка → `Column` (spacing `Theme.popupPadding`) → шапка,
   разделитель, вкладки/действия, список(ы), разделитель, футер.
6. Вставить модуль в `Bar.qml`; при необходимости дополнить README.
7. Проверить: `qmllint` без ошибок, вид совпадает по сетке/цветам с Mihomo,
   одновременно открыт только один попап, пустые состояния — Sentence case.

---

## 9. Скелет

```qml
// <Name>.qml — модуль бара
import QtQuick
import Quickshell

Item {
  id: root
  required property PanelWindow bar   // инъекция из Bar.qml

  BarPopup {
    id: popup
    anchorItem: root
    bar: root.bar
    implicitHeight: content.implicitHeight

    onShown: {
      // специфика модуля: счётчик, refresh
      // <Name>Service.popupsOpen += 1;
      // <Name>Service.refreshAll();
    }
    onHidden: {
      // <Name>Service.popupsOpen -= 1;
      // <Name>Service.resetView();
    }

    <Name>Popup {
      id: content
      anchors.fill: parent
      // onCloseRequested: popup.visible = false       // если нужно
    }
  }

  Text {
    id: label
    text: <Name>Service.barLabel()
    color: <Name>Service.on ? Theme.green : Theme.muted
    font.family: Theme.fontFamily
    font.pixelSize: Theme.fontSize
    font.weight: Theme.fontWeight
    verticalAlignment: Text.AlignVCenter
  }
  implicitWidth: label.implicitWidth
  implicitHeight: label.implicitHeight

  // если ширина подписи меняется на лету
  onImplicitWidthChanged: if (popup.visible) popup.anchor.updateAnchor()

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: {
      if (Date.now() - popup.closedAt < 300) return;
      popup.visible = !popup.visible;
    }
  }
}
```

```qml
// <Name>Popup.qml — содержимое (фрагмент)
Rectangle {
  id: frame
  anchors.fill: parent
  color: Theme.background1
  border.width: Theme.popupFrameWidth
  border.color: Theme.frame
  implicitHeight: col.implicitHeight + 2 * (frame.border.width + Theme.popupPadding)

  Column {
    id: col
    anchors { fill: parent; margins: frame.border.width + Theme.popupPadding }
    spacing: Theme.popupPadding
    // header (h 20) · divider (2, dim) · tabs+actions (h 20)
    // · list (26 × 8) · divider (2, dim) · footer
  }
}
```
