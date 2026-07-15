> **[English version](README.md)**

# dotfiles

Dotfiles в теме Gruvbox для Arch Linux / Hyprland / Zsh / Neovim. Управление симлинками через [GNU Stow](https://www.gnu.org/software/stow/), установка через Python-скрипт.

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
- **Python:** 3.10+
- **Git:** для клонирования и субмодулей

Остальное ставится автоматически через `./install.py setup`.

---

## Установка

### Чистая система (рекомендуется)

```bash
git clone git@github.com:diominvd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.py
./install.py setup
```

Скрипт выполнит:
1. Установку системных пакетов (`stow`, `git`) через pacman
2. Установку Oh My Zsh (если не установлен)
3. Установку Starship (если не установлен)
4. Развёртывание всех симлинков
5. Инициализацию git-субмодулей (nvim, radio, vpn, yandex-music)
6. Настройку git hooks (авто-обновление симлинок при pull/checkout/rebase)

### Уже настроенная система

Если stow и git уже установлены:

```bash
./install.py install
```

### Один пакет

```bash
./install.py link-pkg nvim
./install.py link-pkg hypr
./install.py link-pkg kitty
```

---

## Команды

| Команда | Описание |
|---------|----------|
| `./install.py setup` | Установить зависимости + полная установка |
| `./install.py install` | Полная установка (deps + link + submodules + hooks) |
| `./install.py link` | Развернуть или обновить все симлинки |
| `./install.py link-pkg <name>` | Развернуть один пакет |
| `./install.py force` | Удалить старые симлинки и заново развёрнуть |
| `./install.py clean` | Удалить все симлинки |
| `./install.py verify` | Проверить битые симлинки |
| `./install.py check-deps` | Проверить наличие stow и git |
| `./install.py submodules` | Инициализировать git-субмодули |
| `./install.py hooks` | Настроить git hooks |

### Типичные сценарии

```bash
# Добавил новый конфиг в apps/nvim/
./install.py link

# Стянул изменения с GitHub (хук сработает сам)
git pull

# Переключил ветку (хук сработает сам)
git checkout other-branch

# Конфликт с уже существующими файлами в ~/.config/
./install.py force

# Чистая установка на новой машине
./install.py setup
```

---

## Структура репозитория

```
.dotfiles/
├── apps/              → ~/.config/
│   ├── btop/                      системный монитор
│   ├── elio/                      файловый менеджер
│   ├── fastfetch/                 информация о системе
│   ├── gtk-3.0/                   GTK-тема
│   ├── hypr/                      оконный менеджер Hyprland
│   │   ├── hyprland.conf
│   │   └── components/
│   ├── kitty/                     терминал
│   ├── mako/                      уведомления
│   ├── mihomo-tui/                VPN TUI клиент
│   ├── ncmpcpp/                   MPD клиент
│   ├── nvim/                      Neovim (субмодуль)
│   ├── opencode/                  AI-ассистент
│   ├── rofi/                      лаунчер
│   ├── starship.toml              промпт
│   ├── swaylock/                  блокировка экрана
│   ├── telegram/                  тема Telegram
│   ├── tmux/                      мультиплексор терминалов
│   ├── waybar/                    статус-бар
│   │   ├── config.jsonc           → include modules/*.jsonc
│   │   ├── modules/               модульные конфиги
│   │   ├── style.css              → @import styles/*.css
│   │   ├── styles/                модульные стили
│   │   └── scripts/               пользовательские скрипты
│   └── zsh/                       оболочка
│       ├── .zshrc                 основной конфиг
│       ├── aliases                алиасы
│       ├── exports                переменные окружения
│       ├── functions/             автозагружаемые функции
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
│   │   └── providers/              провайдеры (игнорятся гитом)
│   ├── mpd/                        Music Player Daemon
│   └── scripts/                    вспомогательные скрипты
│       ├── battery.sh
│       ├── disk.sh
│       ├── memory.sh
│       ├── radio/                  (субмодуль)
│       ├── vpn/                    (субмодуль)
│       └── yandex-music/           (субмодуль)
│
├── hooks/                         git hooks
│   ├── post-checkout              обновление после checkout
│   ├── post-merge                 обновление после pull
│   └── post-rebase                обновление после rebase
│
├── install.py                     скрипт установки
├── docs/
│   └── POWER_MANAGEMENT.md        оптимизация питания ASUS TUF
└── .gitignore
```

---

## Как это работает

### Stow

Установщик использует `stow --no-folding` для создания симлинков из трёх исходных директорий:

| Источник | Цель | Содержимое |
|----------|------|------------|
| `home/` | `~/` | Файлы в $HOME (.zshenv) |
| `apps/` | `~/.config/` | Конфиги приложений |
| `system/` | `~/.config/` | Системные сервисы и скрипты |

Каждая поддиректория или файл из источника становится симлинком. Например:
- `apps/nvim/` → `~/.config/nvim/`
- `apps/starship.toml` → `~/.config/starship.toml`
- `home/.zshenv` → `~/.zshenv`

### Git Hooks

После установки настраиваются git hooks в `hooks/`:

- **post-checkout** — запускает `./install.py link` после `git checkout` или `git switch`
- **post-merge** — запускает `./install.py link` после `git pull`
- **post-rebase** — запускает `./install.py link` после `git rebase`

Симлинки всегда синхронизированы с репозиторием после любой операции с ветками.

### Субмодули

Внешние инструменты подключаются как git-субмодули:

| Субмодуль | Путь | Источник |
|-----------|------|----------|
| Конфиг Neovim | `apps/nvim` | github.com/diominvd/neovim |
| Radio CLI | `system/scripts/radio` | github.com/diominvd/radio-cli |
| VPN manager | `system/scripts/vpn` | github.com/diominvd/vpn-manager-cli |
| Yandex Music | `system/scripts/yandex-music` | (личный) |

Инициализируются автоматически через `./install.py install` или `./install.py submodules`.

---

## Секреты

API-ключи и токены **не** хранятся в репозитории.

| Секрет | Расположение | В гите? |
|--------|-------------|---------|
| GEMINI_API_KEY и др. | `~/.config/secrets/env` | Нет |
| GitHub OAuth токен | `~/.config/gh/hosts.yml` | Нет (игнорится) |
| Mihomo подписка | `system/mihomo/config.yaml` | Нет (игнорится) |
| VPN-провайдеры | `system/mihomo/providers/` | Нет (игнорятся) |

### Настройка секретов

1. Создайте файл секретов:
   ```bash
   mkdir -p ~/.config/secrets
   cp ~/.config/zsh/keys.example ~/.config/secrets/env
   ```

2. Отредактируйте `~/.config/secrets/env` и добавьте API-ключи:
   ```bash
   export GEMINI_API_KEY="your-key-here"
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
| [elio](https://github.com/nicokosi/elio) | `apps/elio/` | Файловый менеджер |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | `apps/fastfetch/` | Информация о системе |
| [Hyprland](https://hyprland.org/) | `apps/hypr/` | Wayland композитор |
| [Kitty](https://sw.kovidgoyal.net/kitty/) | `apps/kitty/` | Эмулятор терминала |
| [Mako](https://github.com/emersion/mako) | `apps/mako/` | Демон уведомлений |
| [mihomo-tui](https://github.com/nicokosi/mihomo-tui) | `apps/mihomo-tui/` | VPN TUI клиент |
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

### "stow: existing target is not the same as" / "not empty"

Файлы уже существуют в `~/.config/` и конфликтуют со stow. Используйте force-режим:

```bash
./install.py force
```

### Субмодули пустые

После клонирования нужно инициализировать субмодули:

```bash
./install.py submodules
```

### Git hooks не работают

```bash
./install.py hooks
```

### Найдены битые симлинки

```bash
./install.py verify
# Затем переразверните:
./install.py link
```

### "command not found: stow"

```bash
./install.py setup
# или вручную:
sudo pacman -S stow
```

### "permission denied: ./install.py"

```bash
chmod +x install.py
```

---

## Лицензия

[MIT](https://opensource.org/licenses/MIT)
