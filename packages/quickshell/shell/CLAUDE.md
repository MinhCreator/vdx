# shell — rules for agents

Quickshell config, `qs -c shell`. What exists: [README.md](README.md).

## Layout

```
shell.qml      bars per monitor and every app
apps/          the shell's apps; apps.json is their registry
bar/           Bar (zones), BarLayout (module registry, layout), BarPopup
modules/<id>/  bar modules: <Name>.qml, <Name>Popup.qml, <Name>Service.qml
kit/           UI components, icons/ (outline, solid/)
components/    Hypr (helpers), ScrimWindow, PopupManager, PopupCatcher, Separator
config/        Theme, Colors (from the active theme), ShellSettings, ModuleSettings
scripts/       backends: one JSON object per command, commands in the header
```

Imports: `import qs.<dir>` from the config root. Singletons: `pragma Singleton`
+ `Singleton {}`.

## A module

1. Script `scripts/<id>.sh|py` — the only code that talks to the system. Errors:
   `{"ok": false, "error": "..."}`. None when Quickshell has the data.
2. Service (singleton) — state and actions, owns every `Process` / `Timer`;
   sections `// ---- name ----`; one `run()`, one `parse()`; `popupShown()` /
   `popupHidden()` for work done only while open; `busy`, `status`, `error`.
3. Bar face — `KitBarItem`, a `MouseArea` (click toggles, wheel = quick action),
   `BarPopup` with `ipcTarget`, `function openPopup()` (for the Folder).
4. Popup — root `KitFrame`; reads the service, calls its functions.
5. Register: `BarLayout.modules` (id, label, zone, icon, about, settings) and a
   `Component` in `bar/Bar.qml`. A renamed id goes to `BarLayout.renamed`.
6. Its id in `modules` of a component in `components.toml` (`quickshell` for
   core ones): a module whose components are all off is "not installed".

## An app

Entry in `apps/apps.json`: id, label, icon, about, bind (Hyprland bind
description), ipc + open, `window` {id, title, width, height} for a window of
its own, `settings`, `module` + `moduleSettings` when it has a bar module.
A bar module of an app is set with the app (Shell apps › Bar module tab), not
in Modules.

## UI

Minimal, monospace, sharp corners, near-monochrome. Reference: the Wi-Fi popup.

- Popup: `KitHeader` → `KitLine` → groups separated by `KitLine` → footer.
  No backgrounds under groups.
- Header: icon, title in normal case, subtitle in caps joined by ` · `.
- Group: `KitLabel` in caps (a noun, current value on the right), then rows.
- Row: `KitRow` — label (capitalised) and hint (sentence case, no full stop,
  ≤ ~36 chars) left, control right. On/off `KitSwitch`; choices `KitChoices
  { stretch: true }` in `KitRow { wide: true }`; fields `KitInput`.
- Selected = `background3` fill + ExtraBold, never a colour. Hover =
  `background1` (one step up from the surface).
- Colour means state only: green ok, yellow / orange attention, red error.
  No hex in QML — `Theme.*` only. Dimmed screens use `Theme.scrim`.
- Bar: one colour per item; a missing value shows `--`.
- Key hints: `Super + D`; footers `key action · key action`, lowercase.
- Icons: Material Symbols SVG in `kit/icons`, `fill="#ffffff"`; every icon
  has a filled twin of the same name in `solid/`.
- Refactors keep the look; a new look is prototyped on one popup first.

## Settings

- Shell options: `ShellSettings` (`settings.json`) — property + alias + control.
- Module / app options: `<Name>Settings.qml` of `KitToggleRow` / `KitOptionRow`;
  values `ModuleSettings.get("<id>", "<key>", default)` (`modules.json`). The
  default lives in the module.
- Applied at once, except pickers with a preview (Apply) and fields (Enter).

## Work

- New file: `./install.py link`, then restart. Edits reload live, except
  `IpcHandler` functions.
- Restart: `kill <pid>` (`qs list --all`), then
  `hyprctl eval 'hl.exec_cmd("qs -c shell")'`; exactly one instance.
- Check: `~/.dotfiles/install.py check shell syntax`; `qs log -c shell | grep -E 'ERROR|WARN'`; popups
  `qs -c shell ipc call <id> toggle`; screenshots `grim -g "X,Y WxH"`.
- Don't test overlays that grab the keyboard while the user is typing.

## QML pitfalls

- Old JS engine: no `Array.flatMap`.
- `console.log` is hidden — use `console.warn`.
- `sed -i` replaces the file and breaks live reload — write in place.
- Reserved names: `eval` (method), `state`, `signal`, `status`, `padding`.
- `Column` / `Row` skip zero-size children; no anchors along their axis.
- A `Grid`'s own `columns` / `spacing` in its bindings give NaN.
- No `parent: parent.parent` rebinding — it loops and has frozen the session.
- `Behavior` on a readonly property is not allowed.
- A config error drops the whole bar — restart and read the log at once.
