# Shell redesign: Strict and Material 3

## Audit and direction

The kit already centralised controls, but styles mostly changed fills.
DemiBold body text, ExtraBold selection and 26–28 px navigation flattened
the hierarchy. Material was then too spacious for this desktop; its final
switch is 44×24 and controls are 36 px, compared with 34 px in Strict.
Settings rows are 40 px in both styles. Existing palettes, font choice,
accent targets and corner preferences remain configurable.

Theme owns semantic colours, density, typography and focus. Kit components
own visual/input states. Settings pages compose them; services own system
actions. M3 role mapping follows the [Material colour guidance](https://m3.material.io/styles/color/the-color-system),
adapted to the shell's existing neutral palettes. This is not an HCT palette
generator. No stored keys were renamed or moved.

## Settings structure

| Section | Result |
|---|---|
| Appearance | Style, Accent, Wallpaper and Shape tabs; real control and desktop previews; password-character option removed |
| Themes | Searchable list and scrollable preview; narrow layout stacks; Apply uses the displayed dark/light variant |
| Fonts | One specimen, searchable family rows, installed filter, explicit Apply/install confirmation, separate text-size tab |
| Cursor | Compact searchable theme rows, adaptive shape preview, pending colour changes wait for Apply |
| Animations | One page with General and By area groups; keyboard-operable sample |
| Bar | General / Modules / Hub; visual mode cards and monitor settings in General |
| Bar modules | Filterable list, wrapped descriptions, consistent detail pane and reset |
| Windows | Layout / Appearance tabs, link to shared corner settings |
| Lock screen | Safe sample preview; real Lock remains an explicit action |
| Notifications | Safe preview; duration and history before badge cosmetics |
| Network | Existing Wi-Fi / Hotspot / Ethernet tabs retained; explicit empty hardware/network states |
| Bluetooth | Clear empty paired-device state, surfaced errors, unavailable actions disabled |
| Displays | Responsive arrangement preview and empty-display state |
| Apps | Filterable list, readable descriptions, consistent detail pane |
| About | System / Settings / About tabs; maintenance first, export busy/result feedback |

Search targets and deep links follow the new groups. Existing settings files
remain readable. The old passwordDots key is retained for import
compatibility; password fields always display dots.

## Bar and hub

The module editor separates the selected monitor, live bar preview, module
inspector, searchable available bank and labelled drop zones. A click selects
a module; destination and Earlier / Later controls offer an alternative to
drag. Clicking a chip no longer inadvertently moves it. Folder/separator
placements are restricted to supported destinations. Monitors have their own
tab rather than pushing the editor down the page.

Hub settings have an independent preview pane beside the controls on wide
pages, and above them on narrow ones. The preview uses labelled sample
values and never changes devices. Groups are General and Content; audio/display slider choices are grouped,
and the avatar uses one Choose/Clear row. Width is adjustable from 320 to 480 px. The actual hub defaults
to 400 px, with a compact user avatar/initial, username, current uptime,
optional media and content-sized module chips.

Output volume, microphone, brightness and software-dimming sliders can be
shown independently of module placement. Volume and brightness default on;
existing explicit overrides win. A divider separates sliders from module
actions. The optional avatar is chosen locally; absent/unreadable images
fall back to the user's initial. Uptime comes from the existing cheap CPU
sample, without adding a full hardware poll.

The hub reserves border and right-side content space, clips oversized faces,
and lets module-chip padding open popups while preserving their own wheel
handlers. OSD flashes do not replace the hub while its sliders are in use.
Child bars retain the existing shared model; Solid and Island main layouts
and look options remain independent.

Two reproduced mode bugs were fixed:

- Editing hub opening/player options while Solid was active previously wrote
  Solid's look values. Named-shape accessors now always address Island.
- Copying an Island layout omitted hidden ids, causing hidden modules to
  reappear as newly added modules. Copy now preserves the hidden bank.

## Shared component changes

The colour picker now has a 128 px SV plane, horizontal hue strip, exact HEX,
selected-colour sample, validation and named palette chips. It adapts below
440 px, supports keyboard input and preserves hue for grayscale colours.
Colour fields commit the text actually typed rather than their old external
value. Nested cursor colour editing gets the full section width.

Body text is Normal, labels Medium, selected states DemiBold. Buttons,
switches, segments, selects, sliders and colour controls expose keyboard and
accessibility actions. Focus has a shared ring. Busy/disabled controls cannot
activate. Scrollbars use a transient 2 px thumb and separate content gutters.
Unboxed panes form a grouping boundary, so settings boxes do not span across
unrelated columns.

## Validation and limits

- `./install.py check shell syntax`: shell registry/index and QML syntax.
- `python tests/check_shell_ui.py`: 18 passing Qt Quick checks, including
  keyboard, HEX validation, click-vs-drag, responsive rows, named-mode
  settings, mode independence and hidden-module copying.
- `python -m unittest tests.test_settings_index tests.test_settings_io tests.test_settings_migrate tests.test_shell`:
  33 passing checks of search journeys, persistence/migration and shell wiring.
- All 15 Shell Manager sections and the new subpages were opened through
  live IPC after a supervised restart; the fresh log had no QML errors.
  Representative settings, previews and the actual hub were reviewed on screen.

The offscreen harness runs production controls and layout functions with a
memory-only store and substitutes Quickshell's embedded clipping/container
plugins. It does not verify GPU clipping, Wayland focus grabs or every system
backend action. Arbitrary custom gradients can still have weak contrast
between their endpoints. Bundled application content outside Shell Manager
has not all received a separate screen-by-screen redesign, although it
inherits the shared kit changes.

## Independent usability pass

The second pass removed the overloaded header mode switch and fourth Bar tab.
Solid / Island are now visible cards under General, with appearance, behaviour
and monitor settings below. Hub settings use a larger preview on the right,
compact General / Content groups on the left, one avatar action row, and
checkable Audio / Display slider choices. Available modules open with an
Add modules button, rather than a switch pretending to be a saved option.

Animations no longer spends a tab on three general controls. Notifications
uses Delivery, History and Bar indicators instead of five tiny groups. Font
search and installed filtering share one toolbar. Cursor theme, colour and
size all wait for Apply; Cancel restores all three, and the sample responds
to the pending size.

Apps and Bar modules select a visible item when filtering excludes the old
selection, reveal keyboard selection while scrolling, and show an empty detail
state instead of stale options. Font selection also follows its filter;
Themes disables Apply and hides its old preview when no results match.
These changes keep the existing saved option keys and values.
