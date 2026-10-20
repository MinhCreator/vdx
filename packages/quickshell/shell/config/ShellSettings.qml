pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// User options set in the Shell Manager, kept in the state dir
// (settings.json). Add an option: a property on `state` and a readonly alias
// here, a control in ShellManager's Appearance tab.
Singleton {
  id: root

  readonly property bool solidIcons: state.solidIcons
  readonly property string managerStart: state.managerStart        // main | last: the page the Shell Manager opens on
  readonly property string managerTab: state.managerTab            // the page it was left on
  readonly property string font: state.font                       // family, kept in step with fontconfig
  readonly property int textSize: state.textSize                  // px, the shell's text (Theme.fontSize): 12 | 13 | 14 | 15
  readonly property string underlineAnimation: state.underlineAnimation  // none | grow | slide
  readonly property string wallpaperMode: state.wallpaperMode     // theme | custom | image
  readonly property var wallpaperImages: state.wallpaperImages     // theme -> picture (WallpaperService.pathOf)
  readonly property string wallpaperColor: state.wallpaperColor   // #rrggbb, for custom
  readonly property var wallpaperOutputs: state.wallpaperOutputs   // theme -> {output: picture}: monitors with their own
  readonly property bool pauseMusic: state.pauseMusic             // MPD pauses while another app plays sound
  readonly property bool resumeMusic: state.resumeMusic           // ...and resumes once that sound stops
  readonly property bool barRightSettings: state.barRightSettings // a right click on a bar module opens its options
  readonly property bool barFolderDot: state.barFolderDot         // a dot on the Folder for unseen notices
  readonly property string barDotColor: state.barDotColor         // theme | red | yellow | green | blue: that dot's colour
  readonly property bool material: state.material                 // controls filled, no frames (Appearance › Controls)
  // the accent (Appearance › Accent): two stops, the first the colour, the second
  // the gradient's end when accentGradient is on. A stop is a colour name (theme =
  // the theme's frame colour | red | … | purple) or "custom", its colour in
  // accentCustom (one #rrggbb per stop, "" until one is typed)
  readonly property bool accent: state.accent                     // the accent on at all (off: monochrome)
  readonly property bool accentGradient: state.accentGradient
  readonly property var accentStops: state.accentStops
  readonly property var accentCustom: Array.isArray(state.accentCustom) ? state.accentCustom : ["", ""]
  readonly property var accentWhere: state.accentWhere            // target key -> true: what takes the accent
  readonly property bool passwordDots: state.passwordDots         // password fields show dots, not squares (Appearance › Controls)
  readonly property string corners: state.corners                 // sharp | round: the whole shell's corners
  readonly property int cornerRadius: state.cornerRadius          // px, a popup's corner while round (Theme scales the rest)
  readonly property int controlRadius: state.controlRadius        // px, a control's corner while round (buttons, fields, switches)
  readonly property string barStyle: state.barStyle               // solid | island: one strip, or one live island
  // the look of the bar, kept apart for each shape: switching solid <-> island brings its own back
  readonly property var looks: state.looks                        // shape -> { key: value }
  readonly property int barIconGrow: look("barIconGrow")          // px added to the bar's icons: 0 | 2 | 4
  readonly property bool barSeparators: look("barSeparators")     // "|" between the bar's modules
  readonly property int barGap: look("barGap")                    // px each side of a separator (Theme.separatorMargin)
  readonly property string clockOpens: look("clockOpens")         // hover | click: how the island's hub opens from the clock
  readonly property bool hubPlayer: look("hubPlayer")             // the track (the player) shows in the island's hub
  readonly property var lookDefaults: ({ barIconGrow: 0, barSeparators: true, barGap: 5, clockOpens: "hover", hubPlayer: true })
  // animations (Shell Manager › Animations; Motion reads them)
  readonly property bool motion: state.motion                     // all of them on / off
  readonly property string motionSpeed: state.motionSpeed         // slow | normal | fast
  readonly property string motionPopups: state.motionPopups       // none | fade | slide | grow
  readonly property bool motionPanels: state.motionPanels         // launcher, keybinds, switcher, overview
  readonly property bool motionControls: state.motionControls     // buttons, switches, selects, level bars
  readonly property bool motionBar: state.motionBar               // workspaces, bar values
  readonly property bool motionPages: state.motionPages           // Shell Manager pages and sidebar
  readonly property bool motionIsland: state.motionIsland         // the island morphing between its views
  readonly property bool motionLock: state.motionLock             // the lock screen coming in, a wrong password

  // Whether the Shell Manager window is open (not saved).
  property bool managerOpen: false

  function set(key, value) { state[key] = value; }

  // keys back to their defaults; managerTab is not an option
  readonly property var keys: Object.keys(defaults).filter(k => typeof defaults[k] !== "function"
    && !["objectName", "version", "managerTab"].includes(k))
  function reset(list) { for (const k of list) state[k] = JSON.parse(JSON.stringify(defaults[k])); }
  function changed(list) { return list.some(k => JSON.stringify(state[k]) !== JSON.stringify(defaults[k])); }
  ShellState { id: defaults }

  // the current shape's value of a look option, else its default
  function look(key) {
    const v = (looks[barStyle] ?? {})[key];
    return v === undefined ? lookDefaults[key] : v;
  }

  function setLook(key, value) {
    const all = Object.assign({}, looks);
    all[barStyle] = Object.assign({}, all[barStyle] ?? {}, { [key]: value });
    state.looks = all;
  }

  // until the file is read the options are their defaults (barStyle solid):
  // the bars wait for it (shell.qml), or the island window starts as a strip
  property bool loaded: false
  // no settings.json yet: the shell's very first start (a hint toast, shell.qml); not saved
  property bool firstRun: false

  FileView {
    path: Quickshell.statePath("settings.json")
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoaded: root.loaded = true
    onLoadFailed: error => {
      root.firstRun = error === FileViewError.FileNotFound;
      writeAdapter();
      root.loaded = true;
    }

    ShellState { id: state }
  }
}
