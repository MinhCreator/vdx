# dotfiles — rules for agents

Docs index: [docs/README.md](docs/README.md) — one topic per file; read the
files your change touches, not all of them. In short:

- Configs live in `packages/<pkg>/`, linked file by file: after adding or
  removing a file run `./install.py link`, then `./install.py verify`.
- Theme files override package files (`themes/<theme>/<pkg>/`). Colours by role
  only (`themes/gruvbox/README.md`). Generated themes are never edited by hand:
  change gruvbox or `themes/mktheme.py` and rebuild.
- `/etc` only through `system/` and `./install.py system install` (sudo: give
  the user the command, don't run it).
- Everything installable is a component in `components.toml` (packages,
  links, `/etc` files, bar modules); a new program goes in `pacman`/`aur` of
  the component that needs it, a new file must be owned by one (`links`).
- Hardware comes from `.machine.toml` (`./install.py machine`), never assumed:
  `/etc` files use `@KEY@` placeholders, machine-specific fixes are quirks.
- An installer change comes with a test in `tests/`; `./install.py check`
  (incl. `components`, `tests`, `hypr`) is green before a commit. A change
  to what `setup` does is also run on a clean Arch: `tests/fresh-machine.sh`.
- `./install.py doctor` is the machine's health (check is the repo's).
- No secrets in git; check `git diff --cached` before committing.
- Submodules (`packages/nvim`, `packages/scripts/{yandex-music,radio,vpn}`) are
  changed in their own repositories.
- Commits: `docs/repo/commits.md`. Branch `main`; published
  history is not rewritten without the owner.
- Before each commit run the three checks of `docs/repo/commits.md` › Before a commit (security,
  tests, docs) and tell the user their result.
- Commands that check out old commits: `git -c core.hooksPath=/dev/null …`,
  then `./install.py link`.
- The shell (Quickshell): `packages/quickshell/shell/CLAUDE.md`; its UI rules
  (tokens, controls, wording, Settings pages): `docs/shell/design.md`.
- Don't commit or revert someone else's uncommitted changes without asking.
- Docs upkeep (same commit as the change): fix what the change made wrong;
  a rule or fact you had to find out that is written nowhere goes into its
  topic file; a new file only with a line in `docs/README.md`.
