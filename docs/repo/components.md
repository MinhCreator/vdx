# Components

`components.toml` lists everything that can go on a machine: dotfiles
packages (`kitty`, `quickshell`), features (`vpn`, `yandex-music`) and
hardware (`gpu-nvidia`, `laptop`). Its header documents every field.

- `link`, `deps`, `system` and `setup` act on the **selected** components:
  `[components] selected` in `.machine.toml`, set by the wizard or
  `./install.py components add|remove|set <name>…`.
- With nothing chosen: a machine already set up keeps everything (but
  hardware that wasn't detected); a fresh one gets the catalog's defaults,
  which `setup` previews and saves only after confirmation.
- Every non-core component can be deselected unless a selected component
  requires it. `./install.py components set <name>…` starts from only those
  choices and their requirements; packages for deselected components stay
  installed but are not removed.
- A file belongs to the component whose `links` path matches it longest:
  `zsh` owns `zsh/`, `vpn` owns `zsh/functions/vpn`. Theme overlays follow
  their package. A file nobody owns is linked everywhere and fails `check`.
- `requires` can't be switched off; `suggests` is ticked along, can be
  unticked; `default = false` keeps personal things off for a new machine;
  hardware turns on by `auto` terms (`gpu:nvidia`, `hybrid`, `laptop`,
  `asus`, `quirk:<name>`; `!term` negates).
- Packages count as installed when anything provides them (`pacman -T`:
  `yay-bin` is `yay`).
- A part split off a component (`split_from`, e.g. `shell-backups` off
  `quickshell`) is on wherever its parent is, unless `[components] off`
  names it; leaving it out (wizard, `components remove|set`) writes `off`.
  A selection saved before the split keeps what it had.
