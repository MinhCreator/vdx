# File style and submodules

## File style

- First line: `<program> — <what this file is>` as a comment, then a link to the
  docs if there is one; scripts put it after the shebang. QML: a comment right
  before the root object. Python: the module docstring.
- Section markers: `# Section` in configs, `// ---- name ----` in QML,
  `-- ---- name ----` in Lua.
- Comments explain why or what is not obvious; everything in English.
- Files a program rewrites itself (`btop.conf`, `gh/config.yml`) keep its format.

## Submodules

`packages/nvim`, `packages/scripts/yandex-music`, `packages/scripts/radio`,
`packages/scripts/vpn` change in their own repositories; here only
`git submodule update --remote <path>` and a `<scope>: bump submodule` commit.
Each is listed in `submodules` of its component and cloned only with it.
