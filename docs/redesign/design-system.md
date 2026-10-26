# Design system: two languages × two modifiers

The look is three axes, resolved once in `config/Theme.qml` (section "design
language"); components read the results, never the settings. Paths are under
`packages/quickshell/shell/`. Visual targets: the owner's boards (canvas "Shell
Manager Redesign": `M3*` = Material, `SR*` = Strict).

| Axis | Setting (settings.json) | Theme | Values |
|---|---|---|---|
| Style (the language) | `visualStyle` | `m3` / `strict` | Material · Strict |
| Controls | `material` (bool, old key kept) | `filled` (`material` = old alias) | Filled · Outlined |
| Shape | `corners`, `cornerRadius`, `cornerSplit`, `cornerRadii` | `round`, `cornerOf(part)` | Sharp · Round + R |

2 × 2 × 2 = 8 combinations from one token layer. UI: Appearance › STYLE (Style,
Controls, Shape + Radius, Mode, then a row of real Kit controls as the sample).

## Colour roles (shared ladder)

Material 3 names, mixed from the theme (`background0..3`, `foreground0..2`), so
dark and `-light` themes both work. An M3 "on" colour is `<role>Text`: QML reads a
property named `onX` as a signal handler (it stays black, no error).

| Role | From |
|---|---|
| `surfaceLowest` | background0 toward black (dark, 22 %) / white (light, 50 %) |
| `surface` · `surfaceLow` · `surfaceContainer` · `surfaceHigh` · `surfaceHighest` | bg0 · bg0–bg1 · bg1 · bg1–bg2 · bg2 |
| `surfaceText` · `surfaceVariantText` | fg0 · fg2 |
| `outline` · `outlineVariant` | M3: gray · bg3; Strict: bg3 · bg2–bg3 |
| `primary` · `primaryText` | `accent` (theme = the theme's frame colour, or custom) · bg0 or fg0, whichever contrasts more |
| `primaryContainer` · `primaryContainerText` | surface + 35 % primary (light 30 %) · primary→fg, lifted to 4.5:1 |
| `secondaryContainer` · `secondaryContainerText` | bg1 + 20 % primary · fg + 15 % primary, 4.5:1 |
| `accentContainer` · `accentContainerText` | bg0 + 15 % accent (Strict "on") · accent, 4.5:1 |
| `error` · `errorContainer` · `errorContainerText` | red · surface + red (M3 45 %, Strict 15 %) · 4.5:1 |

State layers: hover 8 % (Strict 6 %), pressed and focus 10 %, disabled opacity
0.38 (Strict 0.4). `Theme.hover(c)` / `pressed(c)`: the content colour over `c`;
over a clear fill, the layer alone (see-through).

## What each part takes

| Part | Material | Strict |
|---|---|---|
| popup / window (`popupFill`) | surfaceContainer + 1 px outlineVariant | surface + 1 px hairline |
| card, Settings box (`cardFill`) | surfaceContainer | surfaceLow |
| well (`wellFill`) | surfaceLowest | surfaceLowest |
| sidebar (`sideFill`) | surfaceLow | surfaceLowest |
| field / select (`fieldFill`) | surfaceHighest | surfaceContainer |
| search bar | surfaceHigh, 48, full | surfaceContainer, 40, full |
| default button | tonal: secondaryContainer | surfaceHigh |
| primary button | primary / primaryText | primary / primaryText |
| picked of a set (`selectedFill`) | secondaryContainer (+ check) | surfaceHighest, fg0, no check |
| switched on (`activeFill`) | primaryContainer | accentContainer + accent text |
| divider (`divider`) | outlineVariant | surfaceHigh |

Outlined (either language): no control fills (`controlFill`, `fieldFill`,
`cardFill` clear), 1 px `outline` frames, cards 1 px `outlineVariant`, the popup
frame `outline` (Material) or the theme's `frame` (Strict, 2 px). Filled: no frames,
popups 1 px `outlineVariant`.

## Sizes (px) and type

| Token | Material | Strict |
|---|---|---|
| `controlHeight` (buttons, icon buttons) | 40 | 36 |
| `fieldHeight` (field, select box) | 56 | 40 |
| `searchHeight` | 48 | 40 |
| `chipHeight` | 32 | 32 |
| `segmentHeight` (Strict: 34 in a 3 px well) | 40 | 40 |
| `sideRowHeight` | 44 | 40 |
| `listRowHeight` (menu, select choice) | 48 | 32 |
| switch | 52 × 32, handle 16 / 24 / 28 pressed, check | 44 × 26, knob 20 |
| slider track / knob | 4 / 20, state layer 40 | 6 / 14 |
| `iconControl` / `iconSide` | 18 / 22 | 16 / 18 |
| `popupPadding` · `cardPadX` · `cardPadY` | 24 · 24 · 12 | 20 · 20 · 16 |
| `sideWidth` | 272 | 224 |

Type is relative to Fonts › Text size (F, 14 by default): control F (M3
labelLarge, 500) / F − 1 (500); row label F + 2 / F (500); hint F / F − 1; typed
text F + 2 / F − 1; sidebar caption F (500) / F − 3 caps; page title F + 14 (400)
/ F + 8 (600); popup title F + 8 / F + 1.

## Shape

The scale at R = 12 (the default), × R / 12 for another R; a full corner never
past h / 2. Sharp: 0, except functional circles (a slider's knob, a spinner, the
switch's state layer).

| Token | Material | Strict |
|---|---|---|
| `radiusSurface` | 28 (extra large) | 24 |
| `radiusCard` | 16 (large) | 16 |
| `radiusWell` | 16 | 12 |
| `radiusField` · `radiusMenu` | 4 (extra small) · 4 | full · 12 |
| `radiusChip` | 8 (small) | full |
| buttons, segments, switches, sidebar rows (`radiusFor(h)`) | full | full |

## Components

`KitButton` (`variant`: filled / tonal / outlined / text, `primary`, `danger`,
`selected`), `KitSwitch`, `KitSegments`, `KitInput` (`search`, M3 floating
`label`), `KitFieldLine` (M3 Filled only), `KitSelect`, `KitSlider`, `KitRow`,
`KitGrouper`, `KitSideRow`, `KitSideCaption`, `KitLine`, `KitFrame`, and the
Shell Manager sidebar branch on these tokens; there is one component set.

## Not done yet

- Fonts: Inter (Strict) / Roboto (Material) are not applied. `ShellSettings.font`
  is the user's family kept in step with fontconfig (default "JetBrainsMono Nerd
  Font"), with no "not chosen" state; a per-style default needs one (e.g. an empty
  value meaning "the style's").
- Only the controls above and the Shell Manager sidebar follow the boards. Page
  headers (title sizes), `EntryList`, `KitChoices`, `KitLabel`, chips, popups'
  own layouts (Hub tiles, Music player) and bespoke rows still use the old tokens.
- Style cards with a live sample of the other style: Theme is global, so the
  sample row shows the current combination only.
- Checked live on Material · Filled · Round 12 only; the other 7 combinations and
  light themes are untested by eye.
