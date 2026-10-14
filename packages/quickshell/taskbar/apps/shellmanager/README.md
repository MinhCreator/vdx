# Shell Manager

Окно настроек оболочки — обычное плавающее окно Hyprland (правило в
`hypr/components/rules.lua`, 820×600). Открывается кнопкой `shell` в баре,
**Super+S** или `qs -c taskbar ipc call shell toggle`; конкретная страница —
`… shell open <themes|wallpaper|bar|plugins>`. Escape закрывает.

Слева — разделы со счётчиками, справа — страница с прокруткой.

## Разделы

- **Themes** — галерея тем из `~/.dotfiles/themes/`: карточка с живым превью
  (бар, терминал, попап в цветах темы) и названием, активная — с галочкой.
  Клик переключает тему через `install.py theme set` (перелинковка всех
  программ, перезагрузка Hyprland / mako / kitty / tmux, бар перезапускается
  сам). Больше шести тем — появляется поиск.
- **Wallpaper** — сплошной цвет обоев через `awww`: цвет темы (`background1`)
  или свой (образцы, поле hex). Превью с полоской бара.
- **Bar** — стиль иконок (solid / контур, с превью) и раскладка: чипы модулей
  перетаскиваются между зонами LEFT / CENTER / RIGHT. `Reset layout` — по
  умолчанию.
- **Plugins** — плитка на плагин, клик включает/выключает.

## Файлы

| Файл | Что |
|---|---|
| `ShellManagerWindow.qml` | Окно (`FloatingWindow`), Escape, IPC `shell` |
| `ShellManager.qml` | Навигация и область страницы |
| `ThemesPage.qml`, `ThemePreview.qml` | Галерея тем и миниатюра |
| `WallpaperPage.qml`, `Wallpaper.qml` | Страница обоев и заливка `awww` |
| `BarPage.qml`, `PluginChip.qml` | Иконки и раскладка бара |
| `PluginsPage.qml` | Плитки плагинов |
| `ThemeService.qml` | Список тем, палитры для превью, переключение |
| `scripts/themes.sh` | Темы и их цвета по ролям из `Colors.qml` каждой темы |

Опции хранит `config/ShellSettings.qml` (`settings.json` в state-папке):
`solidIcons`, `wallpaperMode` (theme | custom), `wallpaperColor`.
