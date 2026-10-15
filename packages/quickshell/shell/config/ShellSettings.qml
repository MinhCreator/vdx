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
  readonly property bool roundIcons: state.roundIcons
  readonly property string font: state.font                       // family, kept in step with fontconfig
  readonly property string underlineAnimation: state.underlineAnimation  // none | grow | slide
  readonly property string wallpaperMode: state.wallpaperMode     // theme | custom | image
  readonly property var wallpaperImages: state.wallpaperImages     // theme -> path under ~/.dotfiles/wallpapers
  readonly property string wallpaperColor: state.wallpaperColor   // #rrggbb, for custom

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
      property bool roundIcons: false
      property string font: "JetBrainsMono Nerd Font"
      property string underlineAnimation: "none"
      property string wallpaperMode: "theme"
      property string wallpaperColor: "#32302f"
      property var wallpaperImages: ({})
    }
  }
}
