import QtQuick
import Quickshell
import Quickshell.Io
import qs.apps.shellmanager
import qs.bar

// Entry point: a bar on every screen, reloaded when the dotfiles theme changes.
Scope {
  Variants {
    model: Quickshell.screens

    Bar {}
  }

  ShellManagerWindow {}

  // `install.py theme set` writes .theme first and relinks Colors.qml after;
  // Quickshell can't see the relink, so reload once it has finished.
  FileView {
    path: Quickshell.env("HOME") + "/.dotfiles/.theme"
    watchChanges: true
    printErrors: false
    onFileChanged: reloadTimer.restart()
  }

  Timer {
    id: reloadTimer
    interval: 400   // longer than install.py's relink (~220 ms)
    onTriggered: Quickshell.reload(true)
  }
}