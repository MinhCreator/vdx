# Redesign audit (Phase 0)

The design system built since: [design-system.md](design-system.md).

2026-10-26, `main` @ `cd73f8a`. Read-only: no code changed. Git/PR state is in
`redesign.md` (Phase 0A, done). Paths are under `packages/quickshell/shell/`.

## 1. What already exists (so we don't rebuild it)

The three axes of the brief are **partly there** under other names:

| Brief axis | Today | Where |
|---|---|---|
| Filled / Outlined | `Appearance › Controls`: Terminal (framed) / Material (filled, no frames) | `ShellSettings.material` → `Theme.material`, `controlFill/Hover`, `frameWidth`, `fillOn/hoverOn` |
| Rounded / Square | `Appearance › Corners`: sharp / round + radius (global or per part: windows, cards, controls, bar) | `ShellSettings.corners/cornerRadius/cornerSplit/cornerRadii` → `Theme.round`, `radiusSurface/Card/Control`, `pill(h)` |
| Accent | `Appearance › Accent`: off by default; 1 colour or gradient; named colour, `theme`, or custom hex; per-place "applies to" list | `ShellSettings.accent*` → `Theme.accent/accentEnd/accentOn(key)` |
| Colour scheme | 14 themes + `-light` twins, generated from gruvbox by `themes/mktheme.py`; applied via `install.py theme set`, pushed live to `Theme.live` | `apps/shellmanager/ThemeService.qml`, `themes/` |
| **Visual style Material / Strict** | **absent** (nearest: "Terminal" look = today's default). New axis. | — |

Tokens: `config/Theme.qml` (colours by role, type, spacing `gap*`, radii,
`hairline/ring/frameWidth`, `qualityColor`) and `config/Motion.qml` (durations,
easing, per-part enable). UI rules: `docs/shell/design.md`. Controls: 39 `Kit*`
files in `kit/` (Button, Switch, Segments, Choices, Select, Input, FieldLine,
Slider, Row, Grouper, Header, Frame…). 

## 2. Architecture map

- **One Quickshell process** (`qs -c shell`, supervised by `supervise.sh`):
  bars, island, popups, every app and the Shell Manager share QML singletons.
  **An in-memory singleton IS shared**: no IPC/daemon is needed for theme
  updates. Only external programs (kitty, hypr, mako, gtk) need files.
- `ShellSettings` (singleton + `FileView` on `settings.json`, `watchChanges`,
  write-through) is already the canonical appearance store; `Theme` derives
  everything reactively from it. `ModuleSettings` (`modules.json`) is the
  per-module/app store (owned by the module, as the brief wants).
- Colours: `Colors.qml` (linked from the active theme) is the fallback;
  `Theme.live` (from `ThemeService`) overrides at runtime. `Colors` already
  works as the safe fallback.
- Shell Manager: `apps/shellmanager/`, 6.2k lines, 15 pages (sidebar captions
  LOOK / DESKTOP / SYSTEM / SHELL), search index in `config/settings-index.json`
  (checked by `install.py check shell`).

## 3. Confirmed problems

1. **Boundary leak (the brief's #1 architecture rule).** `ThemeService`,
   `WallpaperService` live in `apps/shellmanager/` yet are imported by `bar/Bar`,
   `bar/ModuleFaces`, `components/ThemeCurtain`, `modules/{mode,themes,wallpapers}`,
   `shell.qml`, `apps/lock`. The runtime theme provider sits inside the settings
   UI app. Fix = move these services to `config/` (or a `theme/` dir) — mechanical.
2. **Two overlapping style flags, no single "style" concept.** `material` bool +
   `corners` string + `barStyle` string are read ad hoc (`Theme.material` 12
   sites, `Theme.round` 2, ~16 `height / 2`-style literals). Adding Strict as a
   third bool would multiply branches; it needs one resolved layer in `Theme`.
3. **Literal geometry/colour survivors.** 5 literal `radius: N` (KitSlider,
   KitColourPicker, FilesSidebar), 8 hex literals in QML; design.md forbids both.
   Small — fix inside the pilot, not a campaign.
4. **No semantic container roles.** `Theme` has `background0..3` / `foreground0..2`
   (surface ladder, good) but no on-accent text, no `primaryContainer`-style
   role. The accent is a bare colour with a `legible()` helper only for `muted`.
   Custom accent therefore cannot guarantee text-on-accent contrast.
5. **Accent is opt-in per place** ("applies to" keys). Good UX decision already
   made by the owner (colour = state only); M3 "tonal everywhere" would conflict
   with it. Needs an owner decision (see §7).
6. **Settings schema/version mismatch.** Live `settings.json` is **v14**;
   `main`'s `settings_migrate.VERSION = 7`. Code keeps a newer file as is
   (`migrate()` comment), and all live keys exist in `ShellSettings`, so first run is
   safe — but the next real schema step (8) would be ignored by a v14 file.
   Before any schema change: either reset live file's version to 7 (backup is in
   `~/dotfiles-backup-2026-10-26/`) or start numbering at 15. **Owner decision.**
7. No QML behaviour tests; only qmllint syntax + manual `qs log` (docs/shell/testing.md).
   Verification of the 8 combinations must be manual/screenshot (`grim`).
8. Icons: Material Symbols SVGs in `kit/icons` with solid/rounded twins and an
   existing `solidIcons` option — i.e. outline/filled pairs **already exist**.
   Lucide-vs-Phosphor question from the brief is largely moot; recommend
   keeping the set and revisiting later (§7).

## 4. Settings ownership

- Global look (`settings.json`): appearance, accent, corners, motion, wallpaper,
  bar style. Correct owner: shared layer (`ShellSettings` already is; only its
  file location/naming says "shell").
- Module/app options (`modules.json`): owned by the module via `ModuleSettings.get(id,key,default)`;
  Shell Manager pages `*Settings.qml` edit the same key — one value, two UIs. Matches the brief.
- Apps import `ShellSettings`/`Theme`/`Kit*` (public). The only private import
  is the §3.1 leak.

## 5. Risks

- Everything is one process: a QML error in `Theme`/`Kit*` drops bar and lock.
  Prototype in a branch and run `qs log` every step.
- `Theme` is read by hundreds of bindings; changing property names breaks all.
  Keep existing names, add new ones beside.
- Parallel rewrites of Shell Manager pages conflicted badly last time: one
  branch, one page at a time.
- Hyprland/QML traps: `Keys` has no `onHomePressed`; stale
  `HYPRLAND_INSTANCE_SIGNATURE` (docs/shell/testing.md).

## 6. Must not regress

Theme switch without reload (curtain), light/dark twins, per-part corner
sliders, accent "applies to", island/solid bar, motion toggles, settings
search index, Settings export/import, `settings_migrate` tests, `check`
green, all app windows (Files, Music, Backup…) rendering with Kit controls.

## 7. Proposed plan

**Integration:** new branch `redesign/design-system` off `main`; no cherry-picks
of Phosphor/island work yet (they stay in tags). Small commits, `./install.py check` each.

**Step 1 — boundary (no visual change):** move `ThemeService`, `WallpaperService`
out of `apps/shellmanager/` into `config/`; fix imports; `check` + `qs log` clean.

**Step 2 — resolved style layer in `Theme` (pilot):**
- new setting `visualStyle: material | strict` (default = today's look, so
  nothing changes for the owner unless switched).
- keep `material` (→ `componentStyle: filled|outlined`) and `corners` (→ shape) and
  expose tokens: `Theme.surfaceFor(level)`, `containerRole`s (`accentContainer`,
  `onAccent`, `onAccentContainer`) computed once from `accent` with contrast
  check (reuse `legible`/`contrast`). Strict = quieter borders (hairline instead
  of tonal fills), tighter density; same tokens.
- Custom accent: existing picker; add derived roles.

**Step 3 — pilot surface:** the **Appearance page** (`AppearancePage.qml`):
group "Style" (Visual / Shape / Treatment as `KitSegments`), Accent, plus one
inline contextual sample row (card, 2 buttons, switch, field, selected chip on
the real Kit controls) — no permanent preview panel (IA rule). Reset button exists (`KitResetButton`).
Verify 8 combos × (gruvbox, one light theme) × (theme accent, custom).

**Stop for approval** before touching other pages/modules.

**Shell Manager IA (proposal, later):** current sidebar is already close to the brief:
Appearance (+Themes/Fonts/Cursor/Animations) · Bar/Modules/Windows/Lock/Notifications ·
Network/Bluetooth/Displays · Apps/About. Gaps: no Shortcuts page (Keybinds is an
app), Basic/Advanced split missing on long pages (Bar, Modules). Do not reshuffle
before the pilot.

## 8. Decisions needed from the owner

1. Strict = what exactly vs today's "Terminal" look? (Proposal: today's look stays the
   default; Strict is a quieter, denser variant of it, Material is the tonal M3-ish one.)
2. Accent stays opt-in per place, or does Material mode tint surfaces by accent (M3 tonal)?
3. Settings version: reset live file to 7, or continue at 15?
4. Icons: keep Material Symbols + `solidIcons` (recommended), or run the Lucide/Phosphor trial?
5. The web artifacts (Shell Manager Redesign: Hub/Themes/Music/Files/Bar boards; `M3*` and
   `SR*` = Material and Strict variants) — which board is the target look for the pilot page?
