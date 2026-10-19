# Shell design system

The shell's UI rules: tokens, controls, wording, colour, motion. Binding for
every face, popup, window and Settings page of `packages/quickshell/shell/`
(paths below are relative to it). Code rules: `packages/quickshell/shell/CLAUDE.md`.
Split out of it by [decision 0001](../decisions/0001-documentation-system.md) option 3
(2026-10-20, with task 05). Rules without a keyword are MUST (0001); new rules say
MUST / SHOULD / MAY.

## Basics

Minimal, monospace, near-monochrome. Reference: the Wi-Fi popup.

- Corners: Appearance › Shape › Corners (sharp | round + one radius). A radius is
  always a token: `Theme.radiusSurface` (popups, windows, panels),
  `radiusCard` (tiles, previews, cards), `radiusControl` (buttons, fields,
  rows, checkboxes), `Theme.pill(h)` (tracks, knobs, dots); all 0 when sharp.
  An image in a rounded tile sits in a `ClippingRectangle`.
- Controls: Appearance › Controls (outlined | material). A control's frame is
  `Theme.frameWidth` (0 in material), its fill `Theme.controlFill` /
  `controlHover`, a popup's frame `Theme.popupFrame`; never a literal 1.

- Spacing: the gaps and edge insets are `Theme.gapHair` (4), `gapTight` (2),
  `gapSmall` (6), `gapMedium` (8), `gapLoose` (10), `gapWide` (12) and `gapGroup`
  (14); a value that is used once stays a literal.
- Popup: `KitHeader` → `KitLine` → groups separated by `KitLine` → footer.
  No backgrounds under groups.
- Window: the frame is `Theme.windowPadding` (24) on every side and nothing else:
  the header sits at `windowPadding - Theme.headerInset`, a footer at
  `bottomMargin: Theme.windowPadding`. A `KitFrame` window sets `headerInset`
  and `bottomInset` (`Theme.textDescent`) instead of offsets. Popups keep 16.
- Header: icon, title in normal case, subtitle in caps joined by ` · `. Tabs are `KitChoices` on its right; a Shell Manager page lists them as `tabs` + `tab`.
- Group: `KitLabel` in caps (a noun, current value on the right), then rows.
- Row: `KitRow` — label (capitalised) and hint (sentence case, no full stop)
  left, control right. A hint in a wide row ≤ 29 chars (the Modules page
  leaves ~32); elsewhere ≤ ~40. A hint adds something (effect, caveat,
  off-state) or is left out; it never repeats the label.
- Control by the job: a feature on/off → `KitSwitch` (one row per item of a
  set, under a caps label with the count: `APPLIES TO` `3 OF 7`); 2–5 named equal
  alternatives (24h | 12h too) → `KitChoices { stretch: true }` in `KitRow
  { wide: true }`; a size judged by eye with a live result (gaps, radius,
  shares, blur) → `KitSliderRow`, value on the right, snapped to its step; a
  list over 5 or one that changes (monitors, models, tabs) → `KitSelect`; an
  exact number or text → `KitInput` (Enter); a folder or file → `KitInput` + a
  `Choose…` button (`FilesService.pickFolder` / `pick`, the Files window's
  picker); a long list to preview → `PickList` + Apply. A slider of 3–4 stops is chips.
- Wording: visibility toggles `Show …` (hint `Off: icon only`); `Close after …`
  / `Close when its window opens`; `Opens on`; `<Things> shown`. Off / None is
  the first chip; time units in each chip (`5 s`, `30 min`). British spelling.
- Group names: `BAR` (the module's face), `POPUP`, `WINDOW` / `LIST`,
  `OPENING`, `SAFETY` (the "Ask before …" toggles); a row shown only with
  another option sits under it and hides with it.
- Selected = `background3` fill + ExtraBold; its text takes the accent only when
  Choices is on (rule 2). Hover =
  `background1` (one step up from the surface).
- Colour rules (the look has one exception, the accent):
  1. Default: colour is state only. Green ok, yellow / orange attention, red error.
     Everything else is shades of the theme (`Theme.foreground*`, `background*`, `gray`).
  2. Accent: the user's own colour (Appearance › Accent: one colour or a
     gradient, `Theme.accent` / `Theme.accentEnd`). Off by default. It takes only the
     places of APPLIES TO (`Theme.accentOn(key)` / `accentFor(key, fallback)` /
     `accentEndFor`); a new place gets a key there, never a literal colour.
  3. A warning colour is never replaced by the accent: a load, a low battery, an error, a mute keep theirs.
     The active state of a module (on, playing, charging, connected) is the accent's place
     `modules` (APPLIES TO › Bar modules): `Theme.accentFor("modules", <its colour>)`. Its colour
     options then show a note and are disabled (`KitSwatches { disabled }`).
  4. A gradient is a `Gradient` from `accent` to `accentEnd`; a text, a dot or an outline
     takes `accent` alone.
  No hex in QML — `Theme.*` only (a custom colour is picked on the spectrum or typed in Shell Manager and
  kept in settings). Dimmed screens use `Theme.scrim`.
- Text: secondary text (hints, captions, times) is `Theme.muted`, lifted to
  4.5:1 on `background0` in every theme; `gray` is for frames, ticks, icons and
  inactive text only. Sizes are `Theme.fontSize ± n` (Appearance › Font › Text
  size, 12–15), never a literal.
- Bar: one colour per item; a missing value shows `--`.
- Key hints: `Super + S`; footers `key action · key action`, lowercase.
- Icons: Material Symbols SVG in `kit/icons`, `fill="#ffffff"`; every icon
  has a filled twin of the same name in `solid/` and Rounded twins in
  `round/` and `round/solid/` (Material names: `icons/material.txt`).
- Refactors keep the look; a new look is prototyped on one popup first.
- Motion: every animation goes through `config/Motion.qml` — a Behavior takes
  `enabled: Motion.<part>` (popups, panels, controls, bar, pages, lock, island) and a
  duration from it (`quick`, `normal`, `slow`, `ms()`), easing `Motion.easing` (`morph` for a shape that resizes, `tint` for a colour);
  set in Shell Manager › Animations. Rows that show and hide sit in a
  `KitColumn` (KitFrame's column is one): they fade in, the rest glide. A
  list's new row (a Repeater remakes them all): `KitAppear` keyed in the list's
  `KitSeen`. A hover / selected fill fades (`Motion.controls`, `quick`) from
  `Theme.clear`, never `"transparent"` (black: it flashes dark); rows in a
  filled box hover with `Theme.controlHover`, the whole row lit, not the text.

## Settings pages

Added by task 05 ([decision 0002](../decisions/0002-settings-ia.md)).

- MUST: where a setting lives follows the user's area, not the code: every bar
  module's options in Bar modules (an app's module too), an app's own options in
  Apps, Lock screen and Notifications on their own pages.
- MUST — link row: a setting kept on another page shows a row where it is also
  looked for: `KitLinkRow` — label = the setting, hint `In <Page> › <Group>`,
  an `Open` button that goes there.
- MUST — overridden: a row another setting overrides stays visible and
  `disabled`, hint `Set by <Page> › <Row>`; a row meaningless without its parent
  hides with it (above).
- MUST — reset: two-step, `KitResetButton` (`Reset` → `Sure?` for 3 s, then
  back), right of the page's or item's header; disabled while nothing differs
  from the defaults.
- MUST — colour choice: named colours → `KitSwatches`; a free colour →
  `KitColourField` + `KitColourPicker`.
- MUST — error: a failed apply shows red `KitText` under the group that failed,
  wrapped, `Theme.fontSize - 1`; it clears on the next success.
- MUST — pending: an apply that runs (install, reload) shows `busy` on its
  button or a `KitSpinner`; the rest of the page stays usable.
- SHOULD — focus (for 12-C): one token `Theme.focusRing`, a 2 px `foreground2`
  outline at `radiusControl`, on keyboard focus only; Space toggles a switch,
  arrows move Choices, Enter activates; `Accessible.name` = the row's label.
- SHOULD — no "Advanced" fold: rarely used groups go last on their page.
- SHOULD — a page header's subtitle holds at most three parts; group labels
  carry their own values.
- MUST — search: every row's label and hint is a literal string where it can be
  (the search index reads them, `scripts/settings_index.py`).
