# nvim

![preview](/assets/preview.jpg)

Minimal Neovim configuration built with [lazy.nvim](https://github.com/folke/lazy.nvim).

## Table of Contents
* [Features](#features)
* [File Layout](#file-layout)
* [Requirements](#requirements)
* [Installation](#installation)
* [Usage](#usage)
* [Troubleshooting](#troubleshooting)

## Features

* Plug-in management with lazy.nvim — lazy-loading, optimised startup.
* LSP support via mason.nvim + mason-lspconfig (TypeScript, Lua, Rust, Go, and more).
* Blink.cmp — fast, native-LSP‑style autocompletion.
* Telescope — fuzzy finder for files, buffers, help tags, and more.
* Treesitter — syntax highlighting, text objects, and incremental selection.
* Neo‑tree — file explorer with git status integration.
* Bufferline — tab‑like buffer tabs with diagnostics and icons.
* Lualine — minimal status line with mode, git branch, and diagnostics.
* Auto‑sessions — restore cursor position and open buffers on restart.
* Flash — motion with labels, treesitter‑aware target selection.
* Conform — automatic formatting on save.
* Auto‑pairs, commenting, and buffer‑safe deletion helpers.

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
    │   ├── autopairs.lua
    │   ├── comment.lua
    │   └── bufdelete.lua
    └── appearance/
        └── theme.lua
```

| Path | Description |
| --- | --- |
| `init.lua` | Entry point, requires core modules. |
| `lazy-lock.json` | Locked versions of all plugins. |
| `lua/config/options.lua` | Global editor options (`shiftwidth`, `number`, etc.). |
| `lua/config/keymaps.lua` | Custom key bindings. |
| `lua/config/lazy.lua` | Lazy.nvim bootstrap and plugin specs. |
| `lua/config/autocmds.lua` | Autocommands (formatting, highlights, etc.). |
| `lua/plugins/lsp.lua` | LSP configuration and servers. |
| `lua/plugins/mason.lua` | Mason — external tool installer (LSP, DAP, linters). |
| `lua/plugins/treesitter.lua` | Treesitter — syntax highlighting and text objects. |
| `lua/plugins/telescope.lua` | Telescope — fuzzy finder. |
| `lua/plugins/blink.lua` | Blink.cmp — autocompletion engine. |
| `lua/plugins/neo-tree.lua` | Neo-tree — file explorer. |
| `lua/plugins/bufferline.lua` | Bufferline — tab-like buffer bar. |
| `lua/plugins/lualine.lua` | Lualine — status line. |
| `lua/plugins/auto-session.lua` | Auto-sessions — save/restore editor state. |
| `lua/plugins/flash.lua` | Flash — enhanced motion with labels. |
| `lua/plugins/conform.lua` | Conform — automatic formatting. |
| `lua/plugins/autopairs.lua` | Auto-pairs — bracket/quote pairing. |
| `lua/plugins/comment.lua` | Comment — toggle comments. |
| `lua/plugins/bufdelete.lua` | Bufdelete — close buffers without losing layout. |
| `lua/appearance/theme.lua` | Colorscheme setup. |

## Requirements

* Neovim >= 0.10
* Git
* A [Nerd Font](https://www.nerdfonts.com/) (for icons)
* `ripgrep` (for Telescope grep search)
* `make` / C compiler (for Treesitter parsers and some Lua Rocks)

## Installation

```bash
git clone https://github.com/diominvd/nvim.git ~/.config/nvim
nvim --headless "+Lazy! sync" +qa
```

On first launch Lazy.nvim will install all plugins automatically.

## Usage

| Key | Action |
| --- | --- |
| `<Space>` | Leader key |
| `<Space>ff` | Find files (Telescope) |
| `<Space>fg` | Live grep (Telescope) |
| `<Space>fb` | Find open buffers (Telescope) |
| `<Space>e`  | Toggle file explorer (Neo‑tree) |
| `gD` | Go to declaration (LSP) |
| `gd` | Go to definition (LSP) |
| `K`  | Hover documentation (LSP) |
| `<C-n>` | Next buffer |
| `<C-p>` | Previous buffer |
| `s`  | Flash (jump anywhere) |

See `lua/config/keymaps.lua` for the full list.

## Troubleshooting

| Problem | Solution |
| --- | --- |
| Icons are missing / garbled | Install a [Nerd Font](https://www.nerdfonts.com/) and set it in your terminal. |
| Telescope grep finds nothing | Install `ripgrep` (`yay -S ripgrep`). |
| LSP not working for language X | Run `:Mason` and install the corresponding server. |
| Plug-in not loading | Check `:Lazy` for errors. |
