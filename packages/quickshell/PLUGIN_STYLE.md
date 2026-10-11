# Стиль плагинов quickshell (модуль бара + попап)

Правила, по которым сделан плагин **Mihomo** (`Mihomo.qml` + `MihomoPopup.qml` +
`MihomoService.qml`). Новый плагин, собранный по этим правилам, визуально
неотличим от существующих: та же сетка, та же палитра, те же компоненты.

Эталон: `Mihomo*`. Переиспользуемый «хром»: `PopupButton.qml`,
`PopupSwitch.qml`, `PopupSpinner.qml`, `PopupInput.qml`.

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
- **Регистр:** «ярлыки» (заголовок, вкладки, кнопки, подписи футера) —
  ВЕРХНИЙ + `font.letterSpacing: 1`. Статусы и пустые состояния — строчные
  (`connected`, `no providers`).

---

## 1. Состав плагина

Один плагин — до пяти файлов в `packages/quickshell/`:

| Файл | Роль |
|------|------|
| `<Name>.qml` | Модуль бара: `Item` + подпись + `MouseArea` + `PopupWindow` + `HyprlandFocusGrab`. |
| `<Name>Popup.qml` | Содержимое попапа (рамка и вся вёрстка). Не знает про процессы. |
| `<Name>Service.qml` | Синглтон (`pragma Singleton`): состояние, действия, все `Process`/`Timer`. |
| `scripts/<name>.sh` | Слой данных: вся работа с системой, JSON в stdout. |
| — | Если нужен новый «хром» (кнопка/свитч/…), он добавляется отдельным `Popup*.qml` и переиспользуется всеми плагинами. |

Правила разделения:
- **Бар** и **попап** только рисуют `Service`. Никаких `Process`/`Timer` и
  системных вызовов в `<Name>.qml` / `<Name>Popup.qml`.
- **Service** — единственная точка ввода-вывода; бар и попап читают его
  свойства и зовут его функции.
- **Скрипт** печатает JSON в stdout; QML парсит через `StdioCollector`
  (для построчного потока — `SplitParser`, см. `--traffic`).
- Синглтоны (`Theme`, `Colors`, `MihomoService`) Quickshell регистрирует
  автоматически по `pragma Singleton` + имя файла; `qmldir` писать не нужно.
- **Новый файл надо слинковать.** Топ-левел `.qml` попадают в
  `~/.config/quickshell/` отдельными симлинками (`install.py link`). Создав
  новый `.qml`, выполните `python3 install.py link` (или создайте симлинк
  вручную) — иначе загрузка упадёт с `X is not a type`.
- Модуль добавляется в нужный `Row` в `Bar.qml`; глифы/метрики — в `Theme.qml`,
  палитра — в `Colors.qml` активной темы.

---

## 2. Дизайн-токены

### 2.1 Цвета (`Colors.qml` → `Theme.*`)

| Токен | Значение | Где использовать |
|-------|----------|------------------|
| `background0` | `#202020` | фон бара |
| `background1` | `#32302f` | фон попапа (тело рамки) |
| `background2` | `#3c3836` | ховер строки, фон активной вкладки |
| `foreground0` | `#d4be98` | основной текст, выбранное, акцентная полоса, рамка активной вкладки |
| `foreground1`/`foreground2` | `#ddc7a1`/`#bdae93` | редкие текстовые акценты (в Mihomo не используются) |
| `green` | `#a9b665` | «connected», пинг < 150 мс, свитч ON |
| `yellow` | `#d8a657` | пинг < 400 мс |
| `orange` | `#e78a4e` | пинг ≥ 400 мс |
| `red` | `#ea6962` | узел мёртв / ошибка действия |
| `muted` | `#928374` | «disconnected», выключенный свитч, пустые состояния |
| `frame` | `#282828` | рамка попапа, неактивные рамки, дорожка свитча |
| `dim` | `#665c54` | вторичный текст, разделители, неактивная вкладка/иконки, подписи футера |

Правило выбора: **основное/активное → `foreground0`; второстепенное →
`dim`; выключенное/недоступное → `muted`; статус → акцентный цвет.**

### 2.2 Типографика

- База: `font.pixelSize: Theme.fontSize` (13), `font.weight: Theme.fontWeight`.
- Отклонения — только уменьшение:
  - `Theme.fontSize - 1` — значения пинга, счётчики, глифы кнопок;
  - `Theme.fontSize - 2` — подписи вкладок/кнопок;
  - `Theme.fontSize - 3` — статус в шапке, «CURRENT SERVER».
- `font.letterSpacing: 1` — у всех UPPERCASE-ярлыков.
- Обрезка длинного текста — `elide: Text.ElideRight`.

### 2.3 Метрики (`Theme.qml`)

| Токен | Значение | Смысл |
|-------|----------|-------|
| `barHeight` | `34` | высота бара |
| `popupWidth` | `370` | ширина попапа |
| `popupFrameWidth` | `4` | толщина рамки |
| `popupPadding` | `10` | внутренние отступы |
| `popupGap` | `6` | зазор между баром и попапом |
| `mihomoRowHeight` | `26` | высота строки списка |
| `mihomoVisibleRows` | `8` | видимых строк (высота списка = `26 × 8`) |
| `switchWidth` | `34` | ширина свитча |
| `switchKnob` | `14` | ползунок свитча |
| `popupInputHeight` | `24` | высота текстового поля (`PopupInput`) |

Локальные «магические» числа, повторяющиеся в Mihomo (держитесь их):
`Column.spacing = 8`; высота шапки и строки вкладок = `20`; разделитель = `2`;
шапка/вкладки: отступы 6/8, ширина вкладки = `text.implicitWidth + 18`;
пиннед-строка = `36` + зазор `6`; колонка пинга = `52` (`rightMargin 4`);
акцентная полоса = `2`; иконка «dots» = `20`; футер: `spacing 4`, строки `18`,
общий левый край значений = `82`, зазор вправо/вверх = `14`.

---

## 3. Каркас попапа (сверху вниз)

```
Rectangle frame                     color background1, border 4px frame
└── Column col                      margins = 4+10, spacing = 8
    ├── header        (h 20)        иконка · 6 · ЗАГОЛОВОК · 8 · статус   |   справа: gear, switch
    ├── divider       (h 2, dim)
    ├── tab bar       (h 20)        слева вкладки (spacing 6) · справа действия (spacing 6)
    ├── content       (высота = 26×8 [+42])   список(ы) + пустые состояния
    ├── divider       (h 2, dim)
    └── footer        (spacing 4)   две строки по 18: SPEED и TRAFFIC
```

`implicitHeight` попапа = `frame.implicitHeight` =
`col.implicitHeight + 2 × (popupFrameWidth + popupPadding)`.

### Шапка
- Слева: глиф-иконка (`fontSize`), `leftMargin 6` до UPPERCASE-заголовка
  (`fontSize`, `letterSpacing 1`), `leftMargin 8` до статуса
  (`fontSize - 3`, `green`/`muted`).
- Справа `Row` (spacing 6): `PopupButton` с глифом и `PopupSwitch`.

### Вкладки и действия
- Вкладка — `Rectangle` высотой `20`, шириной `text.implicitWidth + 18`,
  `border.width: 1`.
  - активная: `color: background2`, `border.color: foreground0`, текст `foreground0`;
  - неактивная: `color: transparent`, `border.color: frame`, текст `dim`.
- Справа — действия текущей вкладки (одна кнопка на вкладку, `PopupButton`).

### Списки
- `ListView { clip: true; boundsBehavior: Flickable.StopAtBounds }`, фиксированная
  высота делегата `mihomoRowHeight`.
- Делегат-строка: фон `background2` только на ховере и **не** у выбранной;
  выбранная — акцентная полоса `2px` слева цветом `foreground0`.
- Имя: слева, `leftMargin 8`, `elide`, цвет `foreground0` (выбранная) / `dim`.
- Число справа — фиксированная колонка `width 52`, `rightMargin 4`,
  `horizontalAlignment: Text.AlignRight`, `fontSize - 1`, чтобы значения
  не «дрожали».
- Пиннед «CURRENT SERVER» (строка `36` + зазор `6`): подпись `dim`/`fontSize-3`/
  `letterSpacing 1` над значением `foreground0`; справа — тот же пинг-блок.
- Пустое состояние — по центру, `muted`, `fontSize`, строчными
  (`mihomo is off`, `no providers`, `no servers`).

### Футер
- Две строки по `18`, `spacing 4`. Подписи `SPEED:`/`TRAFFIC:` — `dim`,
  `letterSpacing 1`; значения выровнены по общему левому краю `82`; первое
  значение (`↓`) — `foreground0`, второе (`↑`) — `dim`, зазор `14`.

---

## 4. Компоненты «хрома»

### `PopupButton`
- `implicitHeight: 20`; ширина `label.implicitWidth + 14` для текста или `20`
  для глифа.
- Рамка `1px`: вне ховера `frame`, на ховере — цветом `tint`; заливка на ховере
  `background2`.
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
- Дорожка `transparent` с рамкой `1px frame` (на ховере — цветом состояния).
- Ползунок `switchKnob (14)`, `x: 2` / `width - knob - 2`, цвет `onColor`
  (`green`) / `offColor` (`muted`), `Behavior on x { 120ms OutCubic }`.
- `signals: toggled()`; `disabled` → `opacity 0.4`.

### `PopupSpinner`
- `Item 14×14`, глиф `Theme.iconSpinner`, `tint`, `fontSize - 1`.
- `RotationAnimator 0→360`, `800ms`, `Infinite`, `running: visible`.

### `PopupInput`
- Текстовое поле: UPPERCASE-подпись сверху (`fontSize - 3`, `dim`,
  `letterSpacing 1`), под ней квадрат высотой `popupInputHeight (24)`.
- Поле: заливка `background0`, рамка `1px`; в покое `frame`, на ховере `dim`,
  в фокусе `foreground0`. Текст `foreground0`/`fontSize`/, центрирован по
  вертикали, отступы `6` по бокам.
- Плейсхолдер — `Text` внутри `TextInput`, виден только пока поле пустое и не в
  фокусе; цвет `dim`, `elide`.
- Отдаёт наружу `text` и `input` (сам `TextInput`, чтобы вручную звать
  `forceActiveFocus()`); сигналы `textEdited()` (пользовательский ввод) и
  `accepted()` (Enter). `activeFocusOnTab: true` — Tab переводит фокус дальше.
- Владелец биндит `text` на свой стейт и синхронизирует его в `onTextEdited`.

Новый «хром» добавляйте рядом и с теми же принципами (квадрат, `Theme.*`,
ховер `background2`, один сигнал действия).

---

## 5. Взаимодействие и поведение

**Модуль бара**
- `Item` с `implicitWidth/Height` от `Text`; подпись = `Service.barLabel()`.
- Цвет подписи по состоянию (`green` включено / `muted` выключено и т.п.).
- `MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor }`,
  клик — переключение попапа.

**PopupWindow**
- Объявляйте **первым** в модуле (чтобы биндинги на `popup` разрешались).
- `anchor.window: <bar>`, `edges: Edges.Bottom | Edges.Right`,
  `gravity: Edges.Bottom | Edges.Left`.
- Позиция считается в `anchor.onAnchoring` через `mapToItem` (не реактивна):
  `x = mapToItem(...).x - 1`, `y = barHeight - 1`, `height = 1 + popupGap`.
- Когда ширина подписи меняется (`onImplicitWidthChanged`) — `updateAnchor()`.
- `color: "transparent"`, `implicitWidth: popupWidth`,
  `implicitHeight: content.implicitHeight`, `visible: false`, `grabFocus: false`.
- При показе: инкремент счётчика открытых попапов и первичная загрузка данных.

**Закрытие**
- Layer-shell панель не может нести grabbing xdg_popup, поэтому `grabFocus`
  не используется. Внешний клик закрывает `HyprlandFocusGrab` (`active: visible`,
  `onCleared` → `visible = false`).
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

**Форма ввода (по образцу add-provider в Mihomo)**
- Кнопка действия в строке вкладок (`ADD`, `PopupButton`) ставит в `Service`
  флаг `adding`. Пока форма открыта, список и кнопки вкладки скрыты
  (`visible: … && !adding`) — форма их замещает.
- Саму форму объявляйте **последним** ребёнком `content`-`Item` c `z: 2` и
  `anchors.fill: parent`, чтобы она перекрывала список. Внутри — `Column`
  (`spacing 8`): поля `PopupInput`, `Row` с `CANCEL`/`SAVE` и строка ошибки
  (`red`, `fontSize - 2`, `wrapMode: WordWrap`).
- Список `ADD`-кнопок: `SAVE` активна только когда оба поля непустые;
  `busy: Service.addBusy`, `status: Service.addStatus`; по успеху форма
  закрывается сама через ~`900 мс` (успев показать `ok`), по ошибке остаётся
  открытой и через ~`2500 мс` гасит статус.
- Фокус: при показе формы — `forceActiveFocus()` на первом поле плюс один
  повтор через ~`80 мс` (окно может активироваться на такт позже). Клавиатуру
  попапу даёт уже объявленный `HyprlandFocusGrab` — отдельных настроек
  клавиатурного фокуса не нужно.
- Клавиши: `Enter` в поле имени → фокус в URL; `Enter` в URL → отправка
  (сигнал `accepted`); `Escape` → отмена (`Keys.onEscapePressed` на форме,
  событие всплывает от поля).
- Сброс: при закрытии попапа (`PopupWindow.onVisibleChanged`, ветка
  `!visible`) вызовите `Service.closeAddForm()`, чтобы не осталось старого
  ввода. Вся логика (`beginAdd`/`addProvider`/`finishAdd`) — в `Service`.

---

## 6. Семантика состояний

- `connected` → `green`; `disconnected` → `muted`.
- Пинг: `≤ 0` → `red` и текст `—`; `< 150` → `green`; `< 400` → `yellow`;
  иначе `orange`. Формат `«N ms»`, выравнивание вправо.
- Ховер строки — `background2`; выбранное — акцент `2px` + `foreground0`.
- Неактивная вкладка/иконка — `dim`; активная — `foreground0`.
- Пусто/недоступно — `muted`.

---

## 7. Do / Don't

**Do**
- Любой цвет/размер/глиф — через `Theme`.
- Квадраты и штрихи `1/2/4px`; разделители — `2px` `dim`.
- UPPERCASE + `letterSpacing 1` для ярлыков; числа — в фиксированной колонке.
- `PointingHandCursor` и `hoverEnabled: true` на всём кликабельном.
- Держать состояние и ввод-вывод в `Service`, вёрстку — в `Popup`.
- Англоязычные комментарии в коде, объясняющие «почему» и связь с waybar.

**Don't**
- `radius`, тени, градиенты, размытие, `DropShadow`.
- Хардкод цветов/шрифтов/размеров в QML (кроме `"transparent"`).
- Тултипы (`tooltip: false` — как в waybar).
- `Process`/`Timer`/системные вызовы внутри модуля или попапа.
- Анимации сверх свитча и спиннера.
- Свои кнопки/свитчи вместо `PopupButton`/`PopupSwitch`/`PopupSpinner`.

---

## 8. Чеклист нового плагина

1. Добавить цвета (если реально новые) в `Colors.qml`, метрики/глифы — в
   `Theme.qml` (`iconX`, `xIntervalMs`, `xRowHeight`, …).
2. Написать `scripts/<name>.sh`: JSON в stdout, вся системная работа здесь.
3. Написать `<Name>Service.qml` (`pragma Singleton`): состояние, действия,
   `Process`/`Timer`, `barLabel()`, `refresh*()`, `open*()`.
4. Написать `<Name>.qml`: `Item` + `Text` + `MouseArea` + `PopupWindow` +
   `HyprlandFocusGrab` (шапку-эталон копировать из `Mihomo.qml`).
5. Написать `<Name>Popup.qml`: рамка → `Column` (spacing 8) → шапка,
   разделитель, вкладки/действия, список(ы), разделитель, футер.
6. Вставить модуль в `Bar.qml`; при необходимости дополнить README.
7. Слинковать новые файлы: `python3 install.py link` (иначе `X is not a type`).
8. Проверить: `qmllint` без ошибок, вид совпадает по сетке/цветам с Mihomo,
   клавиатурный фокус в полях ввода работает (попап получает фокус через
   `HyprlandFocusGrab`).

---

## 9. Скелет

```qml
// <Name>.qml — модуль бара
Item {
  id: root
  required property var bar           // инъекция из Bar.qml

  PopupWindow {                        // объявлять первым
    id: popup
    anchor.window: root.bar
    anchor.edges: Edges.Bottom | Edges.Right
    anchor.gravity: Edges.Bottom | Edges.Left
    anchor.onAnchoring: {
      const p = root.mapToItem(root.bar.contentItem, root.width, 0)
      anchor.rect.x = Math.round(p.x) - 1
      anchor.rect.y = Theme.barHeight - 1
      anchor.rect.width = 1
      anchor.rect.height = 1 + Theme.popupGap
    }
    color: "transparent"
    implicitWidth: Theme.popupWidth
    implicitHeight: content.implicitHeight
    visible: false
    grabFocus: false

    <Name>Popup { id: content; anchors.fill: parent; onCloseRequested: popup.visible = false }
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

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: popup.visible = !popup.visible
  }

  HyprlandFocusGrab { windows: [popup]; active: popup.visible; onCleared: popup.visible = false }
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
    spacing: 8
    // header (h 20) · divider (2, dim) · tabs+actions (h 20)
    // · list (26 × 8) · divider (2, dim) · footer
  }
}
```
