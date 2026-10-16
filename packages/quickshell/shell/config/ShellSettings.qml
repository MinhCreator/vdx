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
  readonly property int barIconGrow: state.barIconGrow            // px added to the bar's icons: 0 | 2 | 4
  readonly property string managerStart: state.managerStart        // main | last: the page the Shell Manager opens on
  readonly property string managerTab: state.managerTab            // the page it was left on
  readonly property string font: state.font                       // family, kept in step with fontconfig
  readonly property string underlineAnimation: state.underlineAnimation  // none | grow | slide
  readonly property string wallpaperMode: state.wallpaperMode     // theme | custom | image
  readonly property var wallpaperImages: state.wallpaperImages     // theme -> path under ~/.dotfiles/wallpapers
  readonly property string wallpaperColor: state.wallpaperColor   // #rrggbb, for custom
  readonly property bool pauseMusic: state.pauseMusic             // MPD pauses while another app plays sound
  readonly property bool resumeMusic: state.resumeMusic           // ...and resumes once that sound stops
  readonly property bool barRightSettings: state.barRightSettings // a right click on a bar module opens its options
  // animations (Shell Manager › Animations; Motion reads them)
  readonly property bool motion: state.motion                     // all of them on / off
  readonly property string motionSpeed: state.motionSpeed         // slow | normal | fast
  readonly property string motionPopups: state.motionPopups       // none | fade | slide | grow
  readonly property bool motionPanels: state.motionPanels         // launcher, keybinds, switcher, overview
  readonly property bool motionControls: state.motionControls     // buttons, switches, selects, level bars
  readonly property bool motionBar: state.motionBar               // workspaces, bar values
  readonly property bool motionPages: state.motionPages           // Shell Manager pages and sidebar
  readonly property bool motionLock: state.motionLock             // the lock screen coming in, a wrong password

  // Whether the Shell Manager window is open (not saved).
  property bool managerOpen: false

  function set(key, value) { state[key] = value; }

  FileView {
    path: Quickshell.statePath("settings.json")
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()
    onLoadFailed: writeAdapter()

    JsonAdapter {
      id: state
      property bool solidIcons: false
      property int barIconGrow: 0
      property string managerStart: "main"
      property string managerTab: "appearance"
      property string font: "JetBrainsMono Nerd Font"
      property string underlineAnimation: "none"
      property string wallpaperMode: "theme"
      property string wallpaperColor: "#32302f"
      property var wallpaperImages: ({})
      property bool pauseMusic: false
      property bool resumeMusic: true
      property bool barRightSettings: true
      property bool motion: true
      property string motionSpeed: "normal"
      property string motionPopups: "slide"
      property bool motionPanels: true
      property bool motionControls: true
      property bool motionBar: true
      property bool motionPages: true
      property bool motionLock: true
    }
  }
}
