# 05 — Settings inventory (phase 1)

Snapshot 2026-10-20 (commit `c8c7c90`). Part of [05](05_SETTINGS_REDESIGN.md) › Proposal
(items 1, 3, 4). Shell paths are under `packages/quickshell/shell/`.

**Stores.** S `settings.json` (`ShellSettings`) · M `modules.json` `<id>.<key>`
(`ModuleSettings`) · L `layout.json` (`BarLayout`, per role main | extra) ·
W `~/.local/state/dotfiles/windows.json` (+ `window-mode`) · C
`~/.local/state/dotfiles/cursor.json` (`scripts/cursors.py`) · T `.theme`
(`install.py theme set`) · F fontconfig + S `font` · A `scripts/shellapps.py`
window rules · CH cliphist limit (`scripts/clipboard.sh`) · NM NetworkManager ·
BZ BlueZ. The S/M/L/W files are the shell's; C/T/F/A/CH/NM/BZ are system state
the shell only edits.

**Controls.** Sw switch · Ch `KitChoices` · Sel `KitSelect` · Sl `KitSliderRow` ·
In `KitInput` (Enter) · Pk `PickList` / list + Apply · Sws swatches · Bt button ·
Chip drag bands (`KitChipBands`) · Col colour field + picker.

**Applied.** now · Apply · Enter · next (next connect / new chat) · restart.

**Rec.** K keep · M move (→ new place) · G merge · S split · R rename ·
C replace control · X remove. The new pages are in the Proposal › 4.
"Bar modules" = today's Modules page under its new name.

## Appearance (`AppearancePage.qml` and its sections)

| # | Group › row | Key | Store | Default | Control | Shown only with | Applied | Rec |
|---|---|---|---|---|---|---|---|---|
| 1 | Theme › list + search | — | T | gruvbox | Pk + In (search) | — | Apply | K |
| 2 | Accent › Accent | `accent` | S | off | Sw | — | now | K |
| 3 | Accent › Fill | `accentGradient` | S | Solid | Ch | 2 | now | K |
| 4 | Accent › Colour / Gradient | `accentStops`, `accentCustom` | S | blue, purple | Col (×2) | 2 | now | K |
| 5 | Accent › Applies to (7 rows: Switches, Sliders, Choices, Workspaces, Dropdowns, Window border, Bar modules) | `accentWhere.<k>` | S | all off | Sw ×7 | 2 | now | K; "Window border" and "Bar modules" get a hint naming what they override (Proposal › 9) |
| 6 | Wallpaper › Source | `wallpaperMode` | S | Theme | Ch | — | now | K |
| 7 | Wallpaper › Colour | `wallpaperColor` | S | #32302f | Col | 6 = Custom | now | K |
| 8 | Wallpaper › Monitor | — (target of the next pick) | — | Every monitor | Sel | 6 = Image, ≥ 2 monitors | — | K |
| 9 | Wallpaper › pictures | `wallpaperImages`, `wallpaperOutputs` | S | — | thumbs | 6 = Image | now | K |
| 10 | Wallpaper › Add image | — (copies a file) | user folder | — | In + Bt Choose… + Bt Add | 6 = Image | Enter / Add | K |
| 11 | Font › list | `font` | F, S | JetBrainsMono | Pk | — | Apply (may restart) | K |
| 12 | Font › Text size | `textSize` | S | 13 | Ch | — | now | K; hint links Display › GTK apps (Proposal › 9); group R "FONT" → "TEXT" |
| 13 | Cursor › list | base | C | — | Pk | — | Apply | K |
| 14 | Cursor › Colour | mode, fill, outline | C | Original | Ch + Col | Col with Custom | now | K |
| 15 | Cursor › Size | size | C | 24 | Ch | — | now | K |
| 16 | Shape › Corners | `corners` | S | Sharp | Ch | — | now | K; hint "Also windows and toasts" (it sets Hyprland rounding and mako) |
| 17 | Shape › Radius | `cornerRadius` | S | 12 | Sl (stops) | 16 = Round | now | K |
| 18 | Shape › Icons | `solidIcons` | S | Outline | Ch | — | now | K |
| 19 | Controls › Controls | `material` | S | Outlined | Ch | — | now | K; R row "Controls" → "Style" (repeats the group) |
| 20 | Controls › Password dots | `passwordDots` | S | off | Sw | — | now | K |

## Animations (`AnimationsPage.qml`)

| # | Group › row | Key | Store | Default | Control | Shown only with | Applied | Rec |
|---|---|---|---|---|---|---|---|---|
| 21 | General › Animations | `motion` | S | on | Sw | — | now | K |
| 22 | General › Speed | `motionSpeed` | S | Normal | Ch | 21 | now | K |
| 23 | General › Sample | — | — | — | Bt (preview) | 21 | — | K |
| 24 | Parts › Bar popups | `motionPopups` | S | Slide | Ch | 21 | now | K |
| 25 | Parts › Underline | `underlineAnimation` | S | None | Ch | 21 | now | K |
| 26–31 | Parts › Panels, Controls, Bar, Pages, Island, Lock screen | `motionPanels` … `motionLock` | S | on | Sw ×6 | 21 | now | K |

## Bar (`BarPage.qml`)

| # | Group › row | Key | Store | Default | Control | Shown only with | Applied | Rec |
|---|---|---|---|---|---|---|---|---|
| 32 | Look › Shape | `barStyle` | S | Solid | Ch | — | now | K |
| 33 | Look › Icon size | `looks.<style>.barIconGrow` | S | Small (0) | Ch | — | now | K; hint "Kept for each shape" (hidden dependency, Proposal › 2 P-08) |
| 34 | Look › Module gap | `looks.<style>.barGap` | S | Normal (5) | Ch | — | now | K; same hint |
| 35 | Look › Separators | `looks.<style>.barSeparators` | S | on | Sw | — | now | K |
| 36 | Behaviour › Open the hub | `looks.island.clockOpens` | S | Hover | Ch | 32 = Island | now | K |
| 37 | Behaviour › Show the player | `looks.island.hubPlayer` | S | on | Sw | 32 = Island | now | K |
| 38 | Behaviour › Right click opens options | `barRightSettings` | S | on | Sw | — | now | K |
| 39 | Monitor › role chips (Main · X / Extra · Y) | — (which role is edited) | — | main | Ch | ≥ 2 monitors, 41 off | — | K |
| 40 | Monitor › Main monitor | `main` | L | Automatic | Sel | ≥ 2 monitors, 41 off | now | K |
| 41 | Monitor › Same bar everywhere | `shared` | L | off | Sw | ≥ 2 monitors | now | K |
| 42 | Monitor › Show bar | `screens.<role>.off` | L | on | Sw | — | now | K |
| 43 | Monitor › Island clock | `screens.<role>.islandClock` | L | on | Sw | 32 = Island, 42 | now | K |
| 44 | Layout › preview + bands (left / center / right / folder / child bars / hidden), separators | `zones`, `hidden`, `folder`, `bars`, `island` | L | `BarLayout.defaultBar` | Chip | 42 | now | K |
| 45 | Layout › Same as … | — (copies) | L | — | Bt | ≥ 2 roles | now | K |
| 46 | Layout › Reset | — | L | — | Bt | — | now | C: two-step (Proposal › 8) |

## Windows (`WindowsPage.qml`)

| # | Group › row | Key | Store | Default | Control | Shown only with | Applied | Rec |
|---|---|---|---|---|---|---|---|---|
| 47 | Mode › Windows | mode | W `window-mode` | Tiling | Ch | — | now (Hyprland reload) | K |
| 48 | Mode › Scroll with | `scrollKeys` | W | Wheel | Ch | — | now | K |
| 49 | Tiling › Master size | `mfact` | W | 50 % | Sl | 47 = Tiling | now | K |
| 50 | Tiling › New window | `newStatus` | W | Stack | Ch | 47 = Tiling | now | K |
| 51 | Scrolling › Column width | `columnWidth` | W | 1/2 | Ch | 47 = Scrolling | now | K |
| 52 | Floating › Arrange | `arrange` | W | Cascade | Ch | 47 = Floating | now | M → Floating group (one group per mode, not two) |
| 53 | Floating › Switcher | `switcher` | W | on | Sw | 47 = Floating | now | K |
| 54 | Floating › Taskbar | `taskbar` | W | on | Sw | 47 = Floating | now | K |
| 55 | Floating › Shape | `taskbarShape` | W | Strip | Ch | 54 | now | R "Shape" → "Taskbar shape" (two "Shape" rows in the shell) |
| 56 | Decoration › Inner gap | `gapsIn` | W | 10 | Sl | — | now | K |
| 57 | Decoration › Outer gap | `gapsOut` | W | 20 | Sl | — | now | K |
| 58 | Decoration › Frames | `borders` | W | on | Sw | — | now | K; hint links Accent › Window border |
| 59 | Decoration › Shadows | `shadows` | W | on | Sw | — | now | K |

## Network (`NetworkPage.qml`; tabs Wi-Fi, Hotspot, Ethernet)

System state, not shell settings: kept where it is, listed for completeness.

| # | Tab › group › row | Store | Control | Shown only with | Applied | Rec |
|---|---|---|---|---|---|---|
| 60 | Wi-Fi › Wi-Fi | NM | Sw | — | now | K |
| 61 | Wi-Fi › Connection › Speed test, Disconnect, 6 fact rows (Address, Gateway, Channel, Rate, Security, BSSID) | NM | Bt ×2, facts | connected | now | K; facts as a compact block (Proposal › 10, optional) |
| 62 | Wi-Fi › Saved › Show, Network | — | Ch, Sel | — | — | K |
| 63 | Wi-Fi › Saved › Connection, Connect automatically, Priority, DNS, Metered | NM per network | Bt, Sw, Ch, Sel, Ch | a saved network | now / DNS next connect | K |
| 64 | Wi-Fi › New › Name, Password, Join | NM | In, In, Bt | — | Join | K |
| 65 | Hotspot › Hotspot, Name, Password, Channel | NM | Sw, In, In, Ch | card supports it | now / Enter | K |
| 66 | Ethernet › Wired, Connect automatically, Addressing, Address, Gateway, DNS, IPv6, Metered; facts | NM | Sw, Sw, Ch, In, In, Sel/In, Sw, Ch | cable; Address/Gateway with Manual | now / Enter | K |

## Bluetooth (`BluetoothPage.qml`)

| # | Group › row | Store | Control | Shown only with | Applied | Rec |
|---|---|---|---|---|---|---|
| 67 | Bluetooth › Bluetooth, Name, Visible to others, Visible for, Pairable | BZ | Sw, In, Sw, Ch, Sw | adapter | now | K |
| 68 | Connected › a row per device + Disconnect | BZ | Bt | a connected device | now | K |
| 69 | Paired › Device, Connection, Connect automatically, Blocked, Address | BZ | Sel, Bt, Sw, Sw, fact | a paired device | now | K |
| 70 | Nearby › Look for devices (Rescan), a row per device + Pair | BZ | Bt | — | now | K |

## Apps (`ShellAppsPage.qml`; `apps/apps.json`)

Every app with a window (Shell Manager, Task Manager, Cleaner, Clipboard,
Display, Packages, VirusTotal, Files, Backups, Capture) has the same window
block (`WindowOptions.qml` in `WindowDialog`, store A):

| # | Row | Key | Default | Control | Shown only with | Applied | Rec |
|---|---|---|---|---|---|---|---|
| 71 | Window › Set up (opens the dialog) | — | — | Bt | app has a window | — | K |
| 72 | Window, Size, Preset, Width × height, Position (grid + Cursor/Custom), X, Y | mode, size, preset, width, height, position, x, y | per app (`apps.json`) | Ch, Ch, Ch, In×2, grid + Ch, In×2 | Floating; Preset / Custom | now / Enter | K |
| 73 | App › Reset | — (M of the app) | — | Bt | app has options | now | C: two-step |
| 74 | App / Bar module tabs | — | App | Ch | app has a module | — | X: the module's options move to Bar modules; Apps shows a link row (Proposal › 4) |

Per app (M `<id>`):

| # | App › group › row | Key | Default | Control | Shown only with | Rec |
|---|---|---|---|---|---|---|
| 75 | Shell Manager › Opening › Opens on | S `managerStart` | Main page | Ch | — | K |
| 76 | Launcher › Layout › Visible rows, Width, Position | `rows`, `size`, `position` | 8, Medium, Top | Ch ×3 | — | K |
| 77 | Launcher › Tabs (order, hidden) + Reset | `order`, `hidden` | default order, none | Chip + Bt | — | K |
| 78 | Launcher › Opening › Opens on, Clear search on close, English layout on open | `opens`, `clear`, `english` | Apps, on, on | Sel, Sw, Sw | — | K |
| 79 | Keybinds › Layout › Visible rows, Width, Position | `rows`, `size`, `position` | 8, Medium, Top | Ch ×3 | — | K |
| 80 | Keybinds › Opening › Opens on, Clear search on close, English layout on open | `opens`, `clear`, `english` | Mode, on, on | Ch, Sw, Sw | — | K |
| 81 | Lock screen › Look › Background | `lock.background` | Solid | Ch | — | M → Lock screen page |
| 82 | Lock screen › Look › Blur | `lock.blur` | 60 % | Sl | 81 = Blurred | M |
| 83 | Lock screen › Look › Clock | `lock.clock` | 24h | Ch | — | M; R "Clock" → "Clock format" |
| 84 | Lock screen › Look › Date, User | `lock.date`, `lock.user` | on, on | Sw ×2 | — | M; R "Show date", "Show user name" (wording rule `Show …`) |
| 85 | Lock screen › Look › Monitors | `lock.screen` | All | Sel | — | M; group S: it is where, not look → own group WHERE |
| 86 | Lock screen › On screen › Keyboard layout, Power buttons, Hide cursor when idle, Hide after | `layout`, `power`, `hideCursor`, `cursorDelay` | on, on, on, 3 s | Sw ×3, Ch | Hide after with Hide cursor | M |
| 87 | Lock screen › Try it › Lock | — | — | Bt | — | M |
| 88 | Overview | — | — | "No options" row | — | K |
| 89 | Task Manager › List › Group by program, Only my processes, Kernel threads, Sort by, Refresh | `group`, `onlyMine`, `kernel`, `sortBy`, `refresh` | on, off, off, CPU, 2 s | Sw ×3, Ch ×2 | — | K |
| 90 | Task Manager › Safety › Ask before ending | `confirm` | on | Sw | — | K |
| 91 | Cleaner › Safety › Ask before cleaning | `confirm` | on | Sw | — | K |
| 92 | Cleaner › AI › AI mode, Model | `ai`, `model` | on, Haiku | Sw, Ch | Model with AI mode | K |
| 93 | Clipboard › History › Entries kept | CH limit | 100 | Ch (5 values) | — | K |
| 94 | Clipboard › Safety › Ask before clearing | `confirm` | on | Sw | — | K |
| 95 | Display | — | — | "No options" (its window holds Scale, Refresh rate, Position, GTK text size) | — | K; the GTK text size row links Appearance › Text size |
| 96 | Packages › Opening › Opens on, Check on open, Background check, Include the AUR | `startTab`, `checkOnOpen`, `interval`, `aur` | Updates, on, 30 min, on | Ch, Sw, Ch, Sw | — | G: "Check on open", "Background check", "Include the AUR" are not opening → own group UPDATES |
| 97 | Packages › List › Sort installed by, Cache shows | `sortBy`, `cacheView` | Name, Old | Ch ×2 | — | K |
| 98 | Packages › Safety › Ask before uninstalling | `confirm` | on | Sw | — | K |
| 99 | VirusTotal › History › Lookups kept, Keep between runs | `historyKeep`, `keepHistory` | 20, off | Ch, Sw | Keep with Lookups ≠ None | K |
| 100 | VirusTotal › Lookups › Wait for analysis, Report button | `waitSeconds`, `reportAction` | 90 s, Browser | Ch ×2 | — | K |
| 101 | Files › View › Show as, Show preview, Preview lines, Show frames, Show key hints | `view`, `preview`, `previewLines`, `frames`, `hints` | List, on, 40, on, on | Ch, Sw, Ch, Sw, Sw | Preview lines with Show preview | K |
| 102 | Files › List › Show hidden files, Show thumbnails, Dates | `hidden`, `thumbnails`, `dateFormat` | off, on, Short | Sw, Sw, Ch | — | K |
| 103 | Files › Sort › Sort by, Descending, Folders first, Group by | `sortBy`, `sortDesc`, `foldersFirst`, `groupBy` | Name, off, on, None | Ch, Sw, Sw, Ch | — | G: Sort and List into one LIST group (7 rows) — optional |
| 104 | Files › Search › Results kept, Time limit | `searchLimit`, `searchSeconds` | 300, 5 s | Ch ×2 | — | K |
| 105 | Files › Behaviour › Open on one click, Open at, folder | `singleClick`, `startMode`, `startPath` | off, Last folder, ~ | Sw, Ch, In + Choose… | folder with Fixed | R group BEHAVIOUR → OPENING (wording rule) |
| 106 | Files › Terminal | `terminal` | kitty --directory | In | — | K |
| 107 | Files › Picker › Size, Width, Height | `pickerSize`, `pickerWidth`, `pickerHeight` | Medium | Ch, In ×2 | Width/Height with Custom | K |
| 108 | Files › Safety › Ask before deleting, Ask before trashing | `confirmDelete`, `confirmTrash` | on, off | Sw ×2 | — | K |
| 109 | Files › Actions › a row per action + remove; new: label, command, Add | `actions` | [] | Bt, In ×2, Bt | — | K |
| 110 | Backups | — | — | no options page (app module has Bar text only) | — | K |
| 111 | Capture › Shortcut › Shortcut opens | `shortcut` | Popup | Ch | — | K |
| 112 | Capture › Saving › After a screenshot, After a recording | `shotTarget`, `videoTarget` | Save, Save | Ch ×2 | — | K |
| 113 | Capture › Recording › Quality, Frame rate, Codec, Encoder | `quality`, `fps`, `codec`, `encoder` | Medium, 60, Auto, Auto | Ch ×4 | — | K |
| 114 | Capture › Problems (codec issues) | — | — | text | — | K |
| 115 | Capture › Notifications › Notify after a screenshot / a recording | `notifyShot`, `notifyRecord` | on, on | Sw ×2 | — | K; also listed (link) on the Notifications page |
| 116 | Capture › Folders › Screenshots, Recordings | `shotDir`, `videoDir` | XDG | In + Choose… ×2 | — | K |

## Bar module options (today: Modules page, or Apps › Bar module tab for an app's module)

Every module's BAR group starts with **Bar text** (`BarTextRow`, M `<id>.text`:
Content | Name | Icon, default Content; Name | Icon for modules without content).
Rows marked "Content" show only while Bar text = Content.

| # | Module › group › row | Key | Default | Control | Shown only with | Rec |
|---|---|---|---|---|---|---|
| 117 | Workspaces › Bar › Workspaces as | `style` | Digits | Ch | — | K (no Bar text row: K) |
| 118 | Music › Bar › Bar text, Shows, Max length | `text`, `show`, `titleLength` | Content, Both, 60 | Ch ×3 | Content; Max length unless Shows = Icon | K; X the `Component.onCompleted` migration (`titleLength 0`) once slice 1's migration covers it |
| 119 | Radio › Bar › Bar text, Shows, Max length | `text`, `show`, `titleLength` | Content, Title, 60 | Ch ×3 | same | K; same migration note |
| 120 | Themes › Bar › Bar text, Show theme name, Wheel on the bar | `text`, `name`, `barWheel` | Content, on, on | Ch, Sw, Sw | name with Content | K |
| 121 | Themes › Popup › View, English layout on open, Wheel picks | `view`, `english`, `wheel` | Auto, on, on | Ch, Sw, Sw | — | K |
| 122 | Wallpapers › Bar › Bar text, Show picture name, Wheel on the bar | `text`, `name`, `barWheel` | Content, off, on | Ch, Sw, Sw | name with Content | K |
| 123 | Wallpapers › Popup › View, English layout on open, Wheel picks | `view`, `english`, `wheel` | Auto, on, on | Ch, Sw, Sw | — | K |
| 124 | Equalizer › Bar › Colour, Show when paused | `colour`, `showPaused` | Theme, on | Sws, Sw | Colour disabled while Accent › Bar modules | K; hint names the override and where |
| 125 | Clock › Bar › Format, Show seconds, Show date | `twelveHour`, `seconds`, `date` | 24h, off, off | Ch, Sw, Sw | — | K |
| 126 | Brightness › Bar › Bar text, Show brightness | `text`, `percent` | Content, on | Ch, Sw | Content | K |
| 127 | Audio › Bar › Bar text, Show volume | `text`, `percent` | Content, on | Ch, Sw | Content | K |
| 128 | Audio › Auto-pause › Pause on other sound, Resume when it stops | S `pauseMusic`, `resumeMusic` | off, on | Sw ×2 | Resume with Pause | K (revisit with 09-B, the generic player) |
| 129 | Wi-Fi, Bluetooth, Mihomo, Language, Folder › Bar › Bar text | `text` | Content | Ch | — | K; Wi-Fi / Bluetooth add a link row to Network / Bluetooth; Folder a link to Notifications › Unseen dot |
| 130 | Battery › Bar › Bar text, Shows | `text`, `shows` | Content, Icon and charge | Ch ×2 | Content | K |
| 131 | AI › Bar › Bar text, Limit | `text`, `limit` | Content, 5 h | Ch ×2 | Content | K |
| 132 | Notifications › Bar › Bar text, Unseen dot, Dot colour, Bell badge | `text`, S `barFolderDot`, S `barDotColor`, `badge` | Content, on, Red, Off | Ch, Sw, custom dots, Ch | Dot colour with Unseen dot | M → Notifications page › BAR; C dots → `KitSwatches` |
| 133 | Notifications › Toasts › Toast duration | `toastSeconds` | 5 s | Ch | — | M → Notifications page |
| 134 | Notifications › Popup › Rows before scrolling, Close after clear | `rows`, `closeOnClear` | 6, off | Ch, Sw | — | M → Notifications page › HISTORY; R "Rows before scrolling" → "Notifications shown" (wording rule `<Things> shown`) |
| 135 | System (sysmon) › Bar › Bar text, Show CPU load, memory, temperature, GPU load, network speed | `text`, `barPercent`, `barMemory`, `barTemp`, `barGpu`, `barNetwork` | Content, on, off ×4 | Ch, Sw ×5 | — | K; the five "Show …" rows show only with Content (today always shown: P-10) |
| 136 | System › Popup › CPU cores, Memory, GPU, Disks, Network, Sensors | `cores` … `sensors` | on | Sw ×6 | — | K; R "Show CPU cores" … (wording rule) |
| 137 | Windows › Bar › Bar text | `text` | Content | Ch | — | K |
| 138 | Windows › Popup › Close after picking a mode, Close after the grid | `closeOnMode`, `closeOnGrid` | off, off | Sw ×2 | — | K |
| 139 | Chat › Bar › Bar text | `text` | Name | Ch | — | K |
| 140 | Chat › Model › Model | `model` | first free | Sel | — | K (next chat) |
| 141 | Chat › Opencode › Background server | `server` | on | Sw | — | K |
| 142 | Shell | — | — | no options | — | K |
| 143 | Task Manager (app module) › Bar › Bar text; Popup › Programs shown, Close when its window opens | `text`, `popupRows`, `closeOnOpen` | Name, 5, on | Ch ×2, Sw | — | M → Bar modules |
| 144 | Cleaner (app module) › Bar › Bar text; Popup › Categories shown, Close when its window opens | `text`, `biggest`, `closeOnOpen` | Name, 5, on | Ch ×2, Sw | — | M → Bar modules |
| 145 | Clipboard (app module) › Bar › Bar text; Popup › Entries shown, Search field, Close after copying, Close when its window opens | `text`, `rows`, `search`, `closeOnCopy`, `closeOnOpen` | Name, All, on, on, on | Ch ×2, Sw ×3 | — | M → Bar modules |
| 146 | Packages (app module) › Bar › Bar text, Count on the icon, Yellow when pending; Popup › Updates shown, Roll back button, Close when its window opens | `text`, `showCount`, `tint`, `popupRows`, `popupRollback`, `closeOnOpen` | Content, on, on, 5, on, on | Ch, Sw ×2, Ch, Sw ×2 | Count with Content | M → Bar modules |
| 147 | VirusTotal (app module) › Bar › Bar text, Colour by verdict; Popup › Read the clipboard, Close when its window opens | `text`, `tint`, `clipboard`, `closeOnOpen` | Name, on, off, on | Ch, Sw ×3 | — | M → Bar modules |
| 148 | Display, Backups, Capture (app modules) › Bar › Bar text | `text` | Content / Name | Ch | — | M → Bar modules |
| 149 | each module › Reset | — (M `<id>`) | — | Bt | module has options | C: two-step |

## About (`AboutPage.qml`)

| # | Group | Rec |
|---|---|---|
| 150 | Philosophy, Concept, Author, System (versions) | K; + group SETTINGS: Export, Import, Reset everything (Proposal › 8) |

## Not a setting (internal state in S)

`managerTab` (last page, written on every page change), `firstRun` / `loaded`
(not saved), `managerOpen` (not saved). K; `managerTab` stays out of reset and export.

## Counts

ShellSettings: 36 keys (35 options + `managerTab`). Module / app option rows: ~165
in 32 `*Settings.qml`; Shell Manager page rows: ~95 (+ Network / Bluetooth system rows);
39 pages with options (00 / 12 counted 257 rows). Rec totals: K most; M 23 rows
(Lock screen 7 groups of rows, Notifications 4, app-module options 6 blocks,
Arrange 1); R 9; C 4 (three Reset buttons, the dot colour); G 2 (optional);
X 2 (the Apps › Bar module tab; the Music / Radio inline migration, after slice 1).
No option is removed, no key is renamed: every move is a UI move.

Re-walk 2026-10-20 (after S6): every M, R and C row is in its new place and wording;
G optional rows (Files Sort + List) and the Network facts block left as they are;
deviations in the plan's Phase 2 report.
