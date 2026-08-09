> **[English version](README.md)**

# dotfiles

Dotfiles в теме Gruvbox для Arch Linux / Hyprland / Zsh / Neovim. Управление симлинками через собственный Python-скрипт с TUI — без GNU Stow.

| Компонент | Софт |
|-----------|------|
| Оконный менеджер | Hyprland + Waybar + Mako + Rofi + Swaylock |
| Оболочка | Zsh + Oh My Zsh + Starship |
| Редактор | Neovim (lazy.nvim, LSP, Treesitter, Telescope) |
| Терминал | Kitty + tmux |
| Музыка | MPD + ncmpcpp + Yandex Music |
| VPN | Mihomo (Clash Meta) + Krusofiya |
| Прочее | btop, fastfetch, elio, opencode |

---

## Зависимости

- **ОС:** Arch Linux (или производные)
- **Python:** 3.11+
- **Git:** для клонирования и субмодулей
- **uv** (рекомендуется): используется скриптами `radio`, `vpn` и `yandex-music`

Больше ничего не нужно — установщик на чистой стандартной библиотеке Python.

---

## Установка

### Чистая система

```bash
# 1. Предварительные пакеты
sudo pacman -S --needed git python uv

# 2. Oh My Zsh + Starship (нужны конфигу zsh)
ZSH="$HOME/.local/share/oh-my-zsh" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
curl -sS https://starship.rs/install.sh | sh

# 3. Клонирование и развёртывание
git clone git@github.com:diominvd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.py link                          # развернуть все симлинки
git submodule update --init --recursive    # подтянуть nvim, tpm, radio, vpn, yandex-music
git config core.hooksPath hooks            # включить авто-обновление симлинок
```

### Уже настроенная система

Если git уже установлен:

```bash
./install.py link
```

### Makefile (устаревший)

В репозитории также есть `Makefile`, использующий GNU Stow (`make setup`, `make install`, `make link`, ...). Он оставлен для совместимости — для новых установок используйте `./install.py`.

---

## Команды

| Команда | Описание |
|---------|----------|
| `./install.py link` | Развернуть все симлинки (конфликты решаются автоматически) |
| `./install.py update` | Добавить только новые файлы, пропустить существующие/конфликтующие |
| `./install.py force` | Удалить старые симлинки и развернуть заново |
| `./install.py cleanup` | Удалить устаревшие и битые симлинки |
| `./install.py unlink` | Удалить все управляемые симлинки |
| `./install.py status` | Показать статус пакетов (linked/missing/problem) |
| `./install.py verify` | Проверить битые и устаревшие симлинки |
| `./install.py tui` | Интерактивное TUI-меню |

Тот же CLI доступен как `python -m installer` или `uv run install.py` (работает через inline-метаданные PEP 723).

### TUI

```bash
./install.py tui
```

Навигация стрелками или j/k, Enter — выбор, q — выход.

### Типичные сценарии

```bash
# Добавил новый конфиг в apps/nvim/
./install.py update

# Стянул изменения с GitHub (хук сработает сам)
git pull

# Конфликт с уже существующими файлами в ~/.config/
./install.py force

# Диагностика проблем
./install.py status
./install.py verify
```

---

## Как это работает

### install.py

`install.py` — чистый Python-менеджер симлинков без внешних зависимостей (без stow). Предоставляет и CLI, и TUI-интерфейс.

### Менеджер симлинков

Менеджер сканирует три исходные директории и создаёт симлинки, сохраняя структуру пакета:

| Источник | Цель | Пример |
|----------|------|--------|
| `home/` | `~/` | `home/.zshenv` → `~/.zshenv` |
| `apps/` | `~/.config/` | `apps/nvim/init.lua` → `~/.config/nvim/init.lua` |
| `system/` | `~/.config/` | `system/mpd/mpd.conf` → `~/.config/mpd/mpd.conf` |

Каждый пакет получает свою поддиректорию в `~/.config/`, что исключает конфликты имён (например, `mako/config` и `ncmpcpp/config`). Файлы верхнего уровня (как `apps/starship.toml`) линкуются напрямую.

**Правила пропуска:** скрытые файлы пропускаются, если их нет в списке разрешённых (`.zshrc`, `.zshenv`, `.luarc.json`, `.gitignore`); `.git`, `README.md`, `README`, `assets` и `node_modules` не линкуются никогда.

**Разрешение конфликтов:**
- Существующие симлинки, ведущие в нужный источник, сохраняются
- Неверные симлинки заменяются
- Настоящие файлы/директории бэкапятся с расширением `.bak`
- Пустые директории удаляются

**Устаревшие симлинки:** симлинки, ведущие в репозиторий, но больше не управляемые им, обнаруживаются и удаляются командами `link`, `update`, `cleanup` и `verify`.

### Git Hooks

Включите хуки один раз командой `git config core.hooksPath hooks` — дальше они сами поддерживают симлинки в актуальном состоянии:

- **post-checkout** — запускает `./install.py link` после `git checkout` или `git switch`
- **post-merge** — запускает `./install.py link` после `git pull`
- **post-rebase** — запускает `./install.py link` после `git rebase`

Симлинки всегда синхронизированы с репозиторием после любой операции с ветками.

### Субмодули

Внешние инструменты подключаются как git-субмодули:

| Субмодуль | Путь | Источник |
|-----------|------|----------|
| Конфиг Neovim | `apps/nvim` | github.com/diominvd/neovim |
| tmux TPM | `apps/tmux/plugins/tpm` | github.com/tmux-plugins/tpm |
| Radio CLI | `system/scripts/radio` | github.com/diominvd/radio-cli |
| VPN manager | `system/scripts/vpn` | github.com/diominvd/vpn-manager-cli |
| Yandex Music | `system/scripts/yandex-music` | github.com/diominvd/yandex-music-cli |

Инициализируются вручную через `git submodule update --init --recursive` (или устаревшим `make install`).

---

## Структура репозитория

```
.dotfiles/
├── apps/              → ~/.config/
│   ├── btop/                      системный монитор
│   ├── elio/                      файловый менеджер
│   ├── fastfetch/                 информация о системе
│   ├── gtk-3.0/                   GTK-тема
│   ├── hypr/                      оконный менеджер Hyprland (Lua-конфиг)
│   │   ├── hyprland.lua           основной конфиг
│   │   └── components/            модульные конфиги
│   ├── kitty/                     терминал
│   ├── mako/                      уведомления
│   ├── mihomo-tui/                VPN TUI клиент
│   ├── ncmpcpp/                   MPD клиент
│   ├── nvim/                      Neovim (субмодуль)
│   ├── opencode/                  AI-ассистент
│   │   ├── opencode.jsonc         основной конфиг
│   │   ├── tui.json               настройки TUI
│   │   └── command/               пользовательские команды (snapshot, restore)
│   ├── rofi/                      лаунчер
│   │   ├── apps.sh, scripts.sh, boot.sh   режимы лаунчера
│   │   ├── dmenu.sh               скрипт пользовательского меню
│   │   ├── menu.json, scripts.json        пункты меню
│   │   └── config.rasi, colors.rasi       тема
│   ├── starship.toml              промпт
│   ├── swaylock/                  блокировка экрана
│   ├── telegram/                  тема Telegram
│   ├── tmux/                      мультиплексор терминалов
│   │   ├── tmux.conf
│   │   └── plugins/tpm/           TPM plugin manager (субмодуль)
│   ├── waybar/                    статус-бар
│   │   ├── config.jsonc           → include modules/*.jsonc
│   │   ├── modules/               модульные конфиги
│   │   ├── style.css              → @import styles/*.css + colors.css
│   │   ├── styles/                модульные стили
│   │   ├── colors.css             общие переменные цветов
│   │   └── scripts/               пользовательские скрипты
│   └── zsh/                       оболочка
│       ├── .zshrc                 основной конфиг
│       ├── aliases                алиасы
│       ├── exports                переменные окружения
│       ├── functions/             автозагружаемые функции (battery, disk, memory, music, radio, volume, vpn)
│       ├── keys                   заглушка (секреты)
│       └── keys.example           шаблон для keys
│
├── home/              → ~/
│   └── .zshenv                     ZDOTDIR, пути
│
├── system/            → ~/.config/
│   ├── gh/                         GitHub CLI
│   ├── mihomo/                     VPN-прокси
│   │   ├── config.example.yaml     шаблон
│   │   ├── config.yaml             подписка (в git)
│   │   └── providers/              провайдеры (игнорируются гитом)
│   ├── mpd/                        Music Player Daemon
│   └── scripts/                    вспомогательные скрипты
│       ├── battery.sh
│       ├── disk.sh
│       ├── memory.sh
│       ├── colorpaper/             инструмент перекраски изображений
│       ├── radio/                  (субмодуль)
│       ├── vpn/                    (субмодуль)
│       └── yandex-music/           (субмодуль)
│
├── hooks/                         git hooks
│   ├── post-checkout              обновление после checkout
│   ├── post-merge                 обновление после pull
│   └── post-rebase                обновление после rebase
│
├── installer/                     Python-пакет (только stdlib)
│   ├── cli.py                     разбор аргументов
│   ├── commands.py                реализация команд
│   ├── links.py                   логика симлинков
│   ├── tui.py                     TUI-меню
│   ├── config.py                  пути и правила пропуска
│   └── ansi.py                    цвета терминала
│
├── install.py                     точка входа
├── Makefile                       устаревшая альтернатива на stow
├── docs/
│   ├── POWER_MANAGEMENT.md        оптимизация питания ASUS TUF
│   └── POWER_MANAGEMENT_RU.md
└── .gitignore
```

---

## Секреты

API-ключи и токены **не** хранятся в репозитории.

| Секрет | Расположение | В гите? |
|--------|-------------|---------|
| GEMINI_API_KEY и др. | `~/.config/secrets/env` | Нет (подключается zsh) |
| GitHub OAuth токен | `~/.config/gh/hosts.yml` | Нет (создаётся `gh auth login`) |
| Конфиг GitHub CLI | `system/gh/config.yml` | Да (без секретов) |
| Mihomo подписка | `system/mihomo/config.yaml` | Да — содержит токен подписки + HWID |
| VPN-провайдеры | `system/mihomo/providers/` | Нет (игнорируются гитом) |

> **Внимание:** `system/mihomo/config.yaml` сейчас **отслеживается** git и содержит токен подписки и HWID. Если репозиторий публичный — уберите его из индекса (`git rm --cached system/mihomo/config.yaml`) и перевыпустите креды.

### Настройка секретов

1. Создайте файл секретов:
   ```bash
   mkdir -p ~/.config/secrets
   cp ~/.config/zsh/keys.example ~/.config/secrets/env
   ```

2. Отредактируйте `~/.config/secrets/env` и добавьте API-ключи:
   ```bash
   export GEMINI_API_KEY="your-key-here"
   export GOOGLE_GENERATIVE_AI_API_KEY="your-key-here"
   export ANTHROPIC_API_KEY="your-key-here"
   export OPENAI_API_KEY="your-key-here"
   ```

3. Настройте Mihomo VPN:
   ```bash
   cp system/mihomo/config.example.yaml system/mihomo/config.yaml
   # Отредактируйте config.yaml с вашей подпиской и HWID
   ```

**Бэкап:** зашифрованный бэкап в `~/secrets.tar.gz.enc` (AES-256-CBC), пароль в `~/secrets.passphrase`.

---

## Приложения

| Приложение | Путь конфига | Описание |
|------------|-------------|----------|
| [btop](https://github.com/aristocratos/btop) | `apps/btop/` | Системный монитор |
| [elio](https://github.com/elio-fm/elio) | `apps/elio/` | Файловый менеджер |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | `apps/fastfetch/` | Информация о системе |
| [Hyprland](https://hyprland.org/) | `apps/hypr/` | Wayland композитор |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | `apps/kitty/` | Эмулятор терминала |
| [Mako](https://github.com/emersion/mako) | `apps/mako/` | Демон уведомлений |
| [mihomo-tui](https://github.com/MetaCubeX/mihomo-tui) | `apps/mihomo-tui/` | VPN TUI клиент |
| [ncmpcpp](https://github.com/ncmpcpp/ncmpcpp) | `apps/ncmpcpp/` | MPD клиент |
| [Neovim](https://neovim.io/) | `apps/nvim/` | Текстовый редактор |
| [opencode](https://github.com/opencode-ai/opencode) | `apps/opencode/` | AI-ассистент |
| [Rofi](https://github.com/DaveDavenport/rofi) | `apps/rofi/` | Лаунчер приложений |
| [Starship](https://starship.rs/) | `apps/starship.toml` | Промпт оболочки |
| [Swaylock](https://github.com/swaywm/swaylock) | `apps/swaylock/` | Блокировка экрана |
| [Telegram](https://desktop.telegram.org/) | `apps/telegram/` | Тема Telegram |
| [tmux](https://github.com/tmux/tmux) | `apps/tmux/` | Мультиплексор терминалов |
| [Waybar](https://github.com/Alexays/Waybar) | `apps/waybar/` | Статус-бар |
| [Zsh](https://www.zsh.org/) | `apps/zsh/` | Оболочка |

Цветовая схема: **Gruvbox Material Dark** во всех конфигах.

---

## Решение проблем

### Конфликт с уже существующими файлами

Менеджер бэкапит конфликтующие файлы с расширением `.bak`. Чтобы переразвернуть всё заново:

```bash
./install.py force
```

### Субмодули пустые

После клонирования нужно инициализировать субмодули:

```bash
git submodule update --init --recursive
```

### Git hooks не работают

```bash
git config core.hooksPath hooks
```

### Найдены битые симлинки

```bash
./install.py verify
# Затем переразверните:
./install.py link
```

### "permission denied: ./install.py"

```bash
chmod +x install.py
```

---

## Лицензия

[MIT](https://opensource.org/licenses/MIT)
