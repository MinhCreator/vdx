import QtQuick
import Quickshell
import Quickshell.Io

// Quickshell entry point — a top bar for every screen.
//
// Mirrors the waybar config (packages/waybar + theme gruvbox), 1:1:
//   height 34, spacing 2, background #202020,
//   left  = workspaces | separator | media
//   center = clock
//   right = brightness | sep | audio | sep | network | sep | vpn | sep | battery | sep | language

Scope {
  Variants {
    model: Quickshell.screens

    Bar {}
  }

  // Follow the active theme live. `install.py theme set` rewrites this file and
  // *then* retargets Colors.qml (which Quickshell can't watch, since it only
  // watches files it has loaded — the old palette). Watch .theme and hard-reload
  // slightly later, once the relink has finished, to pick up the new palette.
  FileView {
    id: themeWatcher
    path: Quickshell.env("HOME") + "/.dotfiles/.theme"
    watchChanges: true
    printErrors: false
    onFileChanged: reloadTimer.restart()
  }

  Timer {
    id: reloadTimer
    interval: 400  // > install.py's link time (~220ms) so Colors.qml has been retargeted
    onTriggered: Quickshell.reload(true)
  }
}