# nvim

![preview](/assets/preview.jpg)

Minimal Neovim configuration built with [lazy.nvim](https://github.com/folke/lazy.nvim).

## Table of Contents
* [Features](#features)
* [File Layout](#file-layout)
* [Requirements](#requirements)
* [Installation](#installation)
* [Keybindings](#keybindings)
* [Troubleshooting](#troubleshooting)

## Features

* lazy.nvim — lazy-loading, optimised startup.
* LSP via mason.nvim + nvim-lspconfig (Lua, Python, JSON).
* Blink.cmp — autocompletion.
* Telescope — fuzzy finder (files, grep, buffers).
* Treesitter — syntax highlighting, text objects.
* Neo-tree — file explorer with git integration.
* Bufferline — tab-like buffer bar.
* Lualine — status line.
* Auto-sessions — restore editor state on restart.
* Flash — motion with labels.
* Conform — format on save (StyLua, Ruff, fixjson).
* Gitsigns — git hunks, preview, blame.
* Noice / Trouble / Which-key / Todo-comments.

## File Layout

```
~/.config/nvim/
├── init.lua
├── lazy-lock.json
└── lua/
    ├── config/
    │   ├── options.lua
    │   ├── keymaps.lua
    │   ├── lazy.lua
    │   └── autocmds.lua
    ├── plugins/
    │   ├── lsp.lua
    │   ├── mason.lua
    │   ├── treesitter.lua
    │   ├── telescope.lua
    │   ├── blink.lua
    │   ├── neo-tree.lua
    │   ├── bufferline.lua
    │   ├── lualine.lua
    │   ├── auto-session.lua
    │   ├── flash.lua
    │   ├── conform.lua
    │   ├── gitsigns.lua
    │   ├── noice.lua
    │   ├── trouble.lua
    │   ├── which-key.lua
    │   ├── todo-comments.lua
    │   ├── render-markdown.lua
    │   └── autopairs.lua
    └── appearance/
        └── theme.lua
```

## Requirements

* Neovim >= 0.11
* Git
* A [Nerd Font](https://www.nerdfonts.com/)
* `ripgrep`, `fd`
* `make` / C compiler

## Installation

```bash
git clone https://github.com/diominvd/nvim.git ~/.config/nvim
nvim --headless "+Lazy! sync" +qa
```

## Keybindings

Leader is `<Space>`.

### Find (Telescope)

| Key | Action |
| --- | --- |
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>fw` | Grep word under cursor |
| `<leader>fb` | Buffers |
| `<leader>fo` | Recent files |
| `<leader>fh` | Help tags |
| `<leader>ft` | Find TODOs |
| `<leader>fk` | Show keymaps |

### Buffers

| Key | Action |
| --- | --- |
| `<S-h>` / `<S-l>` | Previous / next buffer |
| `<S-x>` | Close buffer (smart) |
| `<S-p>` | Pin buffer |
| `<A-h>` / `<A-l>` | Move buffer left / right |

### Windows

| Key | Action |
| --- | --- |
| `<C-h/j/k/l>` | Navigate windows |
| `<leader>sv` / `<leader>sh` | Vertical / horizontal split |

### LSP

| Key | Action |
| --- | --- |
| `gd` | Go to definition |
| `gr` | Find references |
| `K` | Hover |
| `<C-k>` | Signature help (insert) |
| `<leader>rn` | Rename |
| `<leader>ca` | Code action |

### Git

| Key | Action |
| --- | --- |
| `]h` / `[h` | Next / previous hunk |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Blame line |

### Treesitter Textobjects

| Key | Action |
| --- | --- |
| `af` / `if` | Function (outer / inner) |
| `ac` / `ic` | Class (outer / inner) |
| `aa` / `ia` | Parameter (outer / inner) |
| `]f` / `[f` | Next / previous function |
| `]]` / `[[` | Next / previous class |

### Other

| Key | Action |
| --- | --- |
| `s` / `S` | Flash jump / treesitter |
| `<leader>e` | Toggle file explorer |
| `<leader>fmt` | Format buffer |
| `<leader>xx` | Diagnostics (Trouble) |
| `<leader>xb` | Buffer diagnostics (Trouble) |
| `<leader>mp` | Toggle markdown render |
| `<leader>Q` | Delete session and quit |
| `<leader>r` | Reload config |

See `lua/config/keymaps.lua` for the full list.

## Troubleshooting

| Problem | Solution |
| --- | --- |
| Icons missing | Install a [Nerd Font](https://www.nerdfonts.com/) |
| Telescope grep empty | Install `ripgrep` |
| Telescope find empty | Install `fd` |
| LSP not working | Run `:Mason` and install the server |
| Plug-in not loading | Check `:Lazy` for errors |
