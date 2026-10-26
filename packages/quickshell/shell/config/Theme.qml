pragma Singleton
import QtQuick

// The look: the theme's colours (from its Colors.qml), type, metrics, the
// spacing scale and the colours of a measured value. A module's own numbers
// (polls, limits, its script) live in its service; text formatting in Format,
// paths in Paths. Icons are SVGs in kit/icons, not font glyphs.
QtObject {
  id: root

  // ---- colours (from the active theme's Colors.qml) ----
  // `live` is the active theme's colours read at runtime (ThemeService), so a
  // theme switch recolours everything without reloading the shell.
  property var live: ({})

  readonly property color background0: live.background0 ?? Colors.background0
  readonly property color background1: live.background1 ?? Colors.background1
  readonly property color background2: live.background2 ?? Colors.background2
  readonly property color background3: live.background3 ?? Colors.background3

  readonly property color foreground0: live.foreground0 ?? Colors.foreground0
  readonly property color foreground1: live.foreground1 ?? Colors.foreground1
  readonly property color foreground2: live.foreground2 ?? Colors.foreground2

  readonly property color red:    live.red ?? Colors.red
  readonly property color orange: live.orange ?? Colors.orange
  readonly property color yellow: live.yellow ?? Colors.yellow
  readonly property color green:  live.green ?? Colors.green
  readonly property color aqua:   live.aqua ?? Colors.aqua
  readonly property color blue:   live.blue ?? Colors.blue
  readonly property color purple: live.purple ?? Colors.purple
  readonly property color gray:   live.gray ?? Colors.gray
  // hints and captions: the theme's muted, lifted toward foreground0 until it
  // reads (WCAG 4.5:1 on background0); the theme file keeps its own (kitty's color8)
  readonly property color muted:  legible(live.muted ?? Colors.muted, background0)
  readonly property color frame:  live.frame ?? Colors.frame
  readonly property color dim:    live.dim ?? Colors.dim

  function luminance(c: color): real {
    const f = v => v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
  }
  function contrast(a: color, b: color): real {
    const x = luminance(a), y = luminance(b);
    return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05);
  }
  // c mixed toward foreground0 in 2 % steps until it has 4.5:1 on `on`
  function legible(c: color, on: color): color {
    const to = foreground0;
    for (let t = 0; t < 1; t += 0.02) {
      const m = Qt.rgba(c.r + (to.r - c.r) * t, c.g + (to.g - c.g) * t, c.b + (to.b - c.b) * t, 1);
      if (contrast(m, on) >= 4.5) return m;
    }
    return to;
  }

  // the unseen dot (Bar › Notifications dot colour): a name of the choices;
  // "theme" (and anything else) is the theme's own text colour
  function notifyDot(name) {
    return name === "red" ? red : name === "yellow" ? yellow : name === "green" ? green
         : name === "blue" ? blue : foreground0;
  }

  // the equalizer's colours (Modules › Equalizer): one colour, or a [from, to] gradient across its bars
  function equalizerColours(name) {
    // Appearance › Accent, APPLIES TO Bar modules: the accent takes the bars whatever the choice
    if (accentOn("modules")) return [accent, accentEnd];
    const pair = { sea: ["blue", "green"], sunset: ["yellow", "red"] }[name];
    if (pair) return [notifyDot(pair[0]), notifyDot(pair[1])];
    const one = name === "theme" ? frame : notifyDot(name);
    return [one, one];
  }

  // ---- accent (Appearance › Accent) ----
  // A stop by name: "theme" is the theme's frame colour (the accent that follows
  // the theme), "custom" the typed one. slot: the stop it is for (0 the colour,
  // 1 the gradient's end): a custom colour has one per stop
  function accentColour(name, slot) {
    if (name === "custom") {
      const hex = ShellSettings.accentCustom[slot ?? 0];
      return hex ? Qt.color(hex) : frame;
    }
    if (name === "theme") return frame;
    return { red: red, orange: orange, yellow: yellow, green: green, aqua: aqua, blue: blue, purple: purple }[name] ?? foreground0;
  }
  readonly property bool accentGradient: ShellSettings.accentGradient
  // the gradient's two ends; with one, both are the same colour, so a fill can
  // always be a Gradient from `accent` to `accentEnd`
  readonly property color accent: accentColour(ShellSettings.accentStops[0] ?? "theme", 0)
  readonly property color accentEnd: accentGradient ? accentColour(ShellSettings.accentStops[1] ?? "theme", 1) : accent
  // roles derived from the accent, so a custom colour still reads: text on it,
  // a quiet container tinted by it, and text on that container
  readonly property color accentText: contrast(background0, accent) >= contrast(foreground0, accent) ? background0 : foreground0
  readonly property color accentContainer: mix(background0, accent, 0.15)
  readonly property color accentContainerText: legible(accent, accentContainer)
  // what takes the accent: a target key of Appearance › Accent (off by default)
  function accentOn(key) { return ShellSettings.accent && ShellSettings.accentWhere[key] === true; }
  function accentFor(key, fallback) { return accentOn(key) ? accent : fallback; }

  // ---- type and bar metrics ----
  readonly property string fontFamily: ShellSettings.font     // the system monospace, Shell Manager › Appearance
  readonly property int fontSize: ShellSettings.textSize      // Appearance › Font › Text size
  readonly property int fontWeight: Font.Medium
  readonly property int fontStrong: Font.DemiBold   // a picked item, a title
  readonly property int barHeight: 34
  readonly property int moduleSpacing: 2
  readonly property int edgeMargin: 20
  readonly property int separatorMargin: ShellSettings.barGap   // Bar › Style › Spacing, each side of a separator
  readonly property int workspaceMinWidth: 16
  // Bar › Style island: the island floats this far from the screen's top.
  // barEdge: where the bar ends for windows and popups, either style.
  readonly property bool island: ShellSettings.barStyle === "island"
  readonly property int islandTop: 6
  readonly property int islandHeight: 32
  readonly property int islandFrameWidth: 1      // either control style: it floats over windows
  // the island's corners: in proportion while small (radiusFor), no more than
  // half again a popup's when open (sharp: 0)
  readonly property int islandRadius: round ? Math.round(cornerOf("bar") * 1.5) : 0
  readonly property int barEdge: island ? islandTop + islandHeight : barHeight

  // ==== design language (Appearance › Style · Controls · Shape) ====
  // Three axes resolved here once; components read the results, never the settings.
  //   style    material | strict — the language: which role each part takes, sizes,
  //            type, the shape scale, each control's anatomy (docs/redesign/design-system.md)
  //   filled   Filled | Outlined — controls filled, or framed on the surface (either language)
  //   round    Rounded | Square  — the language's shape scale × the corner slider; Square: 0
  readonly property bool strict: ShellSettings.visualStyle === "strict"
  readonly property bool m3: !strict
  readonly property bool filled: ShellSettings.material      // settings key `material` (Controls › Filled)
  readonly property bool material: filled                    // the old name of `filled`
  readonly property bool dark: luminance(background0) < luminance(foreground0)

  function mix(a: color, b: color, t: real): color {
    return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1);
  }
  // a state layer: `on` over `base` at `a` (a clear base gets the layer alone, see-through)
  function layer(base: color, on: color, a: real): color {
    return base.a === 0 ? Qt.rgba(on.r, on.g, on.b, a) : mix(base, on, a);
  }

  // ---- colour roles (Material 3 names; both languages use the same ladder) ----
  // the theme's background0..3 are the tonal steps; containers are mixed from them
  readonly property color surfaceLowest: mix(background0, dark ? Qt.rgba(0, 0, 0, 1) : Qt.rgba(1, 1, 1, 1), dark ? 0.22 : 0.5)
  readonly property color surface: background0
  readonly property color surfaceLow: mix(background0, background1, 0.5)
  readonly property color surfaceContainer: background1
  readonly property color surfaceHigh: mix(background1, background2, 0.5)
  readonly property color surfaceHighest: background2
  readonly property color surfaceText: foreground0
  readonly property color surfaceVariantText: foreground2
  // `outline` frames an outlined control; `outlineVariant` is a divider, a card's or popup's hairline
  readonly property color outline: m3 ? gray : background3
  readonly property color outlineVariant: m3 ? background3 : mix(background2, background3, 0.5)
  readonly property color outlineActive: m3 ? foreground0 : gray       // an outline hovered
  readonly property color primary: accent
  readonly property color primaryText: accentText
  readonly property color primaryContainer: mix(surface, primary, dark ? 0.35 : 0.3)
  readonly property color primaryContainerText: legible(mix(primary, surfaceText, 0.45), primaryContainer)
  readonly property color secondaryContainer: mix(surfaceContainer, primary, 0.2)
  readonly property color secondaryContainerText: legible(mix(surfaceText, primary, 0.15), secondaryContainer)
  readonly property color error: red
  readonly property color errorText: contrast(background0, red) >= contrast(foreground0, red) ? background0 : foreground0
  readonly property color errorContainer: mix(surface, red, m3 ? 0.45 : 0.15)
  readonly property color errorContainerText: legible(mix(red, surfaceText, m3 ? 0.7 : 0.35), errorContainer)

  // ---- state layers ----
  readonly property real stateHover: m3 ? 0.08 : 0.06
  readonly property real statePressed: 0.10
  readonly property real stateFocus: 0.10
  readonly property real disabledOpacity: m3 ? 0.38 : 0.4
  function hover(c: color): color { return layer(c, surfaceText, stateHover); }
  function pressed(c: color): color { return layer(c, surfaceText, statePressed); }

  // ---- what each part takes (the language's map of roles) ----
  // popups and windows: Material a container with a hairline; Strict the surface with one
  readonly property color popupFill: m3 ? surfaceContainer : surface
  readonly property color popupFrame: filled ? outlineVariant : m3 ? outline : frame
  // an inset well (a preview, a player, a code sample) and a Settings card (KitGrouper)
  readonly property color wellFill: surfaceLowest
  readonly property color cardFill: filled ? (m3 ? surfaceContainer : surfaceLow) : clear
  readonly property color cardFrame: outlineVariant          // an outlined card's hairline
  readonly property color divider: m3 ? outlineVariant : surfaceHigh   // between rows, between groups
  // an app's sidebar (Shell Manager, Files, Music)
  readonly property color sideFill: m3 ? surfaceLow : surfaceLowest
  // fields, selects and search: filled, or framed on the surface
  readonly property color fieldFill: filled ? (m3 ? surfaceHighest : surfaceContainer) : clear
  // a neutral control at rest (an icon button, a chip, a select, a switch's off track)
  readonly property color controlFill: filled ? surfaceHigh : clear
  readonly property color controlHover: hover(controlFill)
  // the default (tonal) button: Material the secondary container, Strict one step up
  readonly property color buttonFill: filled ? (m3 ? secondaryContainer : surfaceHigh) : clear
  readonly property color buttonText: m3 ? (filled ? secondaryContainerText : primary) : surfaceText
  // the picked one of a set (a segment, a sidebar row, a list's choice)
  readonly property color selectedFill: m3 ? secondaryContainer : surfaceHighest
  readonly property color selectedText: m3 ? secondaryContainerText : surfaceText
  readonly property color restText: m3 ? surfaceText : foreground2          // the others of the set
  // something switched on (a quick-settings tile, an active chip)
  readonly property color activeFill: m3 ? primaryContainer : accentContainer
  readonly property color activeText: m3 ? primaryContainerText : accentContainerText
  // a control in a Settings box: the language's fills already sit one step above the card
  function boxed(item) {
    for (let p = item; p; p = p.parent)
      for (const k of p.data ?? []) if (k.isKitGrouper) return true;
    return false;
  }
  function fillOn(boxed) { return controlFill; }
  function hoverOn(boxed) { return controlHover; }

  // ---- sizes (px) ----
  readonly property int controlHeight: m3 ? 40 : 36       // buttons, icon buttons: one height side by side
  readonly property int fieldHeight: m3 ? 56 : 40         // a text field, a select's box
  readonly property int searchHeight: m3 ? 48 : 40        // a search bar
  readonly property int chipHeight: 32
  readonly property int segmentHeight: 40                 // Strict: 34 segments in a 3 px well
  readonly property int segmentInset: m3 ? 0 : 3
  readonly property int sideRowHeight: m3 ? 44 : 40       // a sidebar row
  readonly property int listRowHeight: m3 ? 48 : 32       // a menu's or a select's choice
  readonly property int switchWidth: m3 ? 52 : 44
  readonly property int switchHeight: m3 ? 32 : 26
  readonly property int sliderTrack: m3 ? 4 : 6
  readonly property int sliderKnob: m3 ? 20 : 14
  readonly property int iconControl: m3 ? 18 : 16          // in a button, a field
  readonly property int iconSide: m3 ? 22 : 18             // a sidebar row's
  readonly property int buttonPad: m3 ? 24 : 16            // a button's side padding (with an icon: 16 / 12)
  readonly property int cardPadX: m3 ? 24 : 20
  readonly property int cardPadY: m3 ? 12 : 16

  // ---- type (relative to Fonts › Text size, 14 by default) ----
  readonly property int textControl: m3 ? fontSize : fontSize - 1     // buttons, segments, chips, fields
  readonly property int textLabel: m3 ? fontSize + 2 : fontSize       // a row's label
  readonly property int textHint: m3 ? fontSize : fontSize - 1        // a row's hint, a subtitle
  readonly property int textField: m3 ? fontSize + 2 : fontSize - 1   // typed text
  readonly property int textCaption: m3 ? fontSize : fontSize - 3     // a sidebar's group caption
  readonly property bool captionCaps: strict
  readonly property int textTitle: m3 ? fontSize + 14 : fontSize + 8  // a page's title
  readonly property int titleWeight: m3 ? Font.Normal : Font.DemiBold
  readonly property int textPopupTitle: m3 ? fontSize + 8 : fontSize + 1
  readonly property int controlWeight: Font.Medium
  readonly property int restWeight: m3 ? Font.Medium : Font.Normal     // an unpicked row of a set

  // ---- shape (Appearance › Shape) ----
  // The language's scale at the default radius (12): Material 3 — surfaces 28 (extra large),
  // cards 16 (large), wells 16, chips 8 (small), fields and menus 4 (extra small), buttons,
  // segments, switches and nav rows full. Strict (the boards) — surfaces 24, cards 16,
  // wells 12, every control full. The slider R scales it all (× R / 12; a control never past
  // a half circle); Square: 0, except functional circles (a slider's knob, a spinner).
  readonly property bool round: ShellSettings.corners === "round"
  readonly property var cornerStops: [4, 8, 12, 16, 20, 24]    // the slider's ticks, px
  // a part's R: the one slider's, or the part's own (Corners › Separately)
  function cornerOf(part) {
    return ShellSettings.cornerSplit ? (ShellSettings.cornerRadii[part] ?? ShellSettings.cornerRadius) : ShellSettings.cornerRadius;
  }
  // `base` px of the scale at R
  function shapeAt(base, r) { return Math.round(base * r / 12); }
  function shape(base, part) { return round ? shapeAt(base, cornerOf(part)) : 0; }
  // full: h / 2 at the default and above, in proportion below it
  function fullAt(h, r) { return Math.round(Math.min(h / 2, h / 2 * r / 12)); }
  function scaled(h, r) { return round ? fullAt(h, r) : 0; }
  readonly property int radiusSurface: shape(m3 ? 28 : 24, "windows")    // popups, windows, panels
  readonly property int radiusCard: shape(16, "cards")                    // tiles, boxes, cards
  readonly property int radiusWell: shape(m3 ? 16 : 12, "cards")          // a well inside a card or popup
  readonly property int radiusControl: radiusFor(controlHeight)          // buttons, icon buttons, segments
  readonly property int radiusField: m3 ? shape(4, "controls") : radiusFor(fieldHeight)
  readonly property int radiusChip: m3 ? shape(8, "controls") : radiusFor(chipHeight)
  readonly property int radiusMenu: m3 ? shape(4, "controls") : shape(12, "controls")
  // the corner of a full-rounded control h px high
  function radiusFor(h) { return round ? fullAt(h, cornerOf("controls")) : 0; }
  // the bar's: the island and its child bars
  function barRadiusFor(h) { return round ? fullAt(h, cornerOf("bar")) : 0; }
  // tracks, knobs, switches
  function pill(h) { return radiusFor(h); }

  // ---- popups (kit) ----
  // the dimmed screen under the launcher, the keybinds and the overview
  readonly property color scrim: Qt.rgba(background0.r, background0.g, background0.b, 0.7)
  // no fill, in a raised tone: a fade to or from it never passes through black
  // ("transparent" is a black with no alpha)
  readonly property color clear: Qt.rgba(surfaceHigh.r, surfaceHigh.g, surfaceHigh.b, 0)

  // the spacing scale: between the items of a column, in px
  readonly property int gapTight: 2
  readonly property int gapHair: 4
  readonly property int gapSmall: 6
  readonly property int gapMedium: 8
  readonly property int gapLoose: 10          // also an edge inset of a row
  readonly property int gapWide: 12
  readonly property int gapGroup: 14
  // icons and the widths of a side column (Shell Manager's pages, the sidebar)
  readonly property int iconSmall: 14
  readonly property int iconLarge: 24
  readonly property int sideWidth: m3 ? 272 : 224
  readonly property int popupPadding: m3 ? 24 : 20   // a popup's frame, every side (KitFrame)
  readonly property int popupWidth: 370
  // a window's frame: the gap to its edges on every side, and the space the
  // title's line keeps above its capitals (the header draws that far into its box)
  readonly property int windowPadding: 24
  readonly property int headerInset: 3
  readonly property int controlWidth: 300        // a setting's choices / field (KitRow wide)
  readonly property int buttonWidth: 120         // a setting's action button (text only, right aligned)
  readonly property int rowStackBelow: 480       // a wide KitRow narrower than this puts its control under the label
  readonly property int popupGap: 6
  readonly property int frameWidth: filled ? 0 : 1            // controls: buttons, selects, fields
  readonly property int windowFrameWidth: filled || m3 ? 1 : 2         // popup frames, like hypr windows, mako
  readonly property int hairline: 1                           // an outline in either style: wells, previews, cards at rest
  readonly property int ring: 2                               // the picked card's or tile's outline
  readonly property int visibleRows: 8
  readonly property int popupStatusMs: 2500       // how long ok / error marks stay
  readonly property string ellipsis: "\u2026"

  // ---- the colour of a measured value ----
  // Green / yellow / orange for a measured value. Thresholds may ascend
  // (lower is better: ping, loss) or descend (higher is better: signal).
  function qualityColor(value, good, fair) {
    const lowerIsBetter = good <= fair;
    if (lowerIsBetter ? value <= good : value >= good) return green;
    if (lowerIsBetter ? value <= fair : value >= fair) return yellow;
    return orange;
  }

  // Latency color shared by every module; no measurement reads as muted.
  readonly property int pingGoodMs: 100
  readonly property int pingFairMs: 300

  function pingColor(ms) {
    return ms > 0 ? qualityColor(ms, pingGoodMs, pingFairMs) : muted;
  }

  // Load of a resource in %: yellow from 70, red from 90.
  function loadColor(percent) {
    return percent >= 90 ? red : percent >= 70 ? yellow : foreground0;
  }
}
