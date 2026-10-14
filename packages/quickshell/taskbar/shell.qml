import QtQuick
import Quickshell
import Quickshell.Io
import qs.apps.shellmanager
import qs.bar
import qs.components

// Entry point: a bar on every screen that has one on (BarLayout), recoloured when the dotfiles theme changes.
Scope {
  Variants {
    model: Quickshell.screens.filter(s => BarLayout.barOn(s.name))

    Bar {}
  }

  ShellManagerWindow {}

  Wallpaper {}

  PopupCatcher {}

  // `install.py theme set` (here or from a terminal) writes .theme; reread the
  // palettes and the shell recolours live — Colors.qml only seeds the start.
  FileView {
    path: Quickshell.env("HOME") + "/.dotfiles/.theme"
    watchChanges: true
    printErrors: false
    onFileChanged: refreshTimer.restart()
  }

  Timer {
    id: refreshTimer
    interval: 400   // longer than install.py's relink (~220 ms)
    onTriggered: ThemeService.refresh()
  }
}