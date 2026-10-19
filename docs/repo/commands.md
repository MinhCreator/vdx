# Commands

`./install.py <command>`.

| Command | |
|---|---|
| `./install.py` | menu with a status overview |
| `install` | the wizard, then `setup` |
| `setup [--dry-run] [--noconfirm] [-y]` | preflight, the plan, each step with work |
| `update [--dry-run] [--noconfirm] [-y]` | `git pull --ff-only`, then `setup` with the new code |
| `doctor` | this machine's health, each problem with its fix |
| `components [list \| add \| remove \| set <name>…]` | what is on this machine |
| `machine [show \| detect]` | the hardware profile |
| `link` · `verify` · `status` | links: create · check · per package |
| `deps [--check]` | missing packages of the selected components |
| `system status \| install` | `/etc` files of the selected components |
| `check [group…]` | the repo: links, syntax, themes, components, tests, hypr, shell, repo |
| `theme list \| current \| set <name>` | themes |
| `secrets [status \| restore]` | `private/` |
| `uninstall [--system]` · `rollback [stamp]` | links and generated files off · backed-up files back |
| `force` · `unlink` · `cleanup` · `bootstrap [-f]` | re-link all · remove all links · only stale ones · the secrets template |
