# dotfiles

Gruvbox-themed dotfiles для Arch Linux / Hyprland / Zsh / Neovim.

## Быстрый старт

```bash
git clone git@github.com:diominvd/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make install
```

После `make install`:
- все конфиги расставлены по местам через симлинки
- git hooks настроены — симлинки обновляются автоматически после `git pull` / `git checkout`

## Рабочий процесс

```bash
# Добавил новый файл (плагин nvim, модуль waybar, скрипт) в apps/
make link

# Стянул изменения с GitHub
git pull                    # ← хук сработает сам

# Переключил ветку
git checkout other-branch   # ← хук сработает сам

# Полная переустановка на новой системе
make install
```

## Структура репозитория

```
.dotfiles/
├── apps/          → ~/.config/    # конфиги приложений
│   ├── aider/                     # AI-ассистент (aider)
│   ├── btop/                      # системный монитор
│   ├── elio/                      # файловый менеджер
│   ├── fastfetch/                 # информация о системе
│   ├── gtk-3.0/                   # GTK тема
│   ├── hypr/                      # оконный менеджер Hyprland
│   ├── kitty/                     # терминал
│   ├── mako/                      # уведомления
│   ├── mihomo-tui/                # VPN TUI клиент
│   ├── mpv/                       # медиаплеер
│   ├── ncmpcpp/                   # MPD клиент
│   ├── nvim/                      # редактор Neovim
│   ├── opencode/                  # AI-ассистент (opencode)
│   ├── rofi/                      # лаунчер
│   ├── starship.toml              # промпт
│   ├── swaylock/                  # блокировка экрана
│   ├── telegram/                  # тема Telegram
│   ├── tmux/                      # терминальный мультиплексор
│   ├── waybar/                    # статус-бар
│   │   ├── config.jsonc           #   → include config/*.jsonc
│   │   ├── config/                #   модульные конфиги
│   │   ├── style.css              #   → @import styles/*.css
│   │   ├── styles/                #   модульные стили
│   │   └── scripts/               #   пользовательские скрипты
│   └── zsh/                       # оболочка Zsh
│       ├── .zshrc                 #   основной конфиг
│       ├── aliases                #   алиасы
│       ├── exports                #   переменные окружения
│       ├── functions/             #   автозагружаемые функции
│       ├── keys                   #   заглушка (секреты вынесены)
│       └── keys.example           #   шаблон для keys
│
├── home/          → ~/            # файлы в $HOME
│   ├── .zshenv                   #   ZDOTDIR, пути
│   └── .aider.conf.yml           #   конфиг aider
│
├── system/        → ~/.config/    # системные сервисы и скрипты
│   ├── gh/                       #   GitHub CLI (config.yml)
│   ├── mihomo/                   #   VPN-прокси
│   │   ├── config.example.yaml   #     шаблон (секреты вынесены)
│   │   └── providers/            #     провайдеры (игнорятся гитом)
│   ├── mpd/                      #   Music Player Daemon
│   └── scripts/                  #   вспомогательные скрипты
│       ├── battery.sh
│       ├── disk.sh
│       ├── memory.sh
│       └── vpn/
│
├── hooks/                        # git hooks
│   ├── post-merge                #   make link после pull
│   └── post-checkout             #   make link после checkout
│
├── Makefile                      # link / clean / install
├── README.md
├── docs/
│   └── POWER_MANAGEMENT.md       # оптимизация питания ASUS TUF
└── .gitignore
```

## Управление (Makefile)

| Команда | Что делает |
|---|---|
| `make link`      | Развернуть или обновить симлинки (все 3 директории) |
| `make clean`     | Удалить все симлинки |
| `make install`   | `make link` + настроить git hooks |

Все новые файлы внутри уже расстонованных директорий подхватываются одной командой `make link`.

## Секреты

API-ключи и токены вынесены из репозитория:

| Что | Где хранится | В гите |
|---|---|---|
| GEMINI_API_KEY, etc. | `~/.config/secrets/env` | нет |
| GitHub OAuth токен | `~/.config/gh/hosts.yml` | нет (игнорится) |
| Mihomo subscription | `system/mihomo/config.yaml` | нет (игнорится) |
| Прокси-провайдеры | `system/mihomo/providers/` | нет (игнорятся) |

**Бэкап:** `~/secrets.tar.gz.enc` (AES-256-CBC), пароль в `~/secrets.passphrase`.

## Цвета

Единая палитра **Gruvbox Material Dark** во всех конфигах: Hyprland, Kitty, Waybar, Mako, Swaylock, Rofi, Neovim, Telegram, btop.

## Состав

- **WM:** Hyprland + Waybar + Mako + Rofi + Swaylock
- **Шелл:** Zsh + Oh My Zsh + Starship
- **Редактор:** Neovim (lazy.nvim, LSP, Treesitter, Telescope)
- **Терминал:** Kitty + tmux
- **Музыка:** MPD + ncmpcpp + Yandex Music
- **VPN:** Mihomo (Clash Meta) + Krusofiya
- **Прочее:** btop, fastfetch, elio, opencode, aider
